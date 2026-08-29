import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { PostsService } from '../posts/posts.service';
import { NewsFetcherService } from './news-fetcher.service';

interface BotRow {
  id: string;
  region: string | null;
  username: string | null;
  avatarSeed: string;
}

@Injectable()
export class BotPostingService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(BotPostingService.name);
  private posting = false;
  private botQueue: BotRow[] = [];
  private queueIndex = 0;
  private timer: ReturnType<typeof setTimeout> | null = null;
  private destroyed = false;

  constructor(
    private readonly prisma: PrismaService,
    private readonly posts: PostsService,
    private readonly news: NewsFetcherService,
    private readonly config: ConfigService,
  ) {}

  private enabled(): boolean {
    if (this.config.get('BOT_POSTING_ENABLED', 'true') !== 'true') return false;
    return this.config.get('BOT_WORKER', 'true') === 'true';
  }

  /** Random delay 35–75s between posts so the feed feels organic */
  private nextDelayMs(): number {
    const min = Number(this.config.get('BOT_POST_MIN_DELAY_MS', '35000'));
    const max = Number(this.config.get('BOT_POST_MAX_DELAY_MS', '75000'));
    return min + Math.floor(Math.random() * (max - min));
  }

  async onModuleInit() {
    if (!this.enabled()) {
      this.logger.log('Real-time bot posting disabled');
      return;
    }

    await this.refreshBotQueue();
    const count = this.botQueue.length;
    if (count === 0) {
      this.logger.warn('No bot accounts — run npm run db:seed');
      return;
    }

    this.logger.log(`${count} bots ready — staggered real-time news posting active`);
    this.scheduleNext();
  }

  onModuleDestroy() {
    this.destroyed = true;
    if (this.timer) clearTimeout(this.timer);
  }

  private scheduleNext() {
    if (this.destroyed || !this.enabled()) return;
    const delay = this.nextDelayMs();
    this.timer = setTimeout(() => void this.postNextInQueue(), delay);
  }

  private async refreshBotQueue() {
    this.botQueue = await this.prisma.user.findMany({
      where: { isBot: true, bannedAt: null },
      select: { id: true, region: true, username: true, avatarSeed: true },
      orderBy: { createdAt: 'asc' },
    });
  }

  private startOfHour(): Date {
    const d = new Date();
    d.setMinutes(0, 0, 0);
    return d;
  }

  private async alreadyPostedThisHour(botId: string): Promise<boolean> {
    const recent = await this.prisma.post.findFirst({
      where: { authorId: botId, createdAt: { gte: this.startOfHour() } },
      select: { id: true },
    });
    return !!recent;
  }

  private async postNextInQueue() {
    if (this.posting || this.destroyed || !this.enabled()) {
      this.scheduleNext();
      return;
    }

    this.posting = true;
    try {
      if (this.botQueue.length === 0) await this.refreshBotQueue();
      if (this.botQueue.length === 0) return;

      let attempts = 0;
      const maxAttempts = Math.min(this.botQueue.length, 5);

      while (attempts < maxAttempts) {
        const bot = this.botQueue[this.queueIndex % this.botQueue.length];
        this.queueIndex++;

        if (!(await this.alreadyPostedThisHour(bot.id))) {
          await this.postRealNewsForBot(bot);
          break;
        }
        attempts++;
      }
    } finally {
      this.posting = false;
      this.scheduleNext();
    }
  }

  async postRealNewsForBot(bot: BotRow): Promise<boolean> {
    const region = this.news.resolveRegion(bot);
    if (!region) {
      this.logger.warn(`No region mapping for bot ${bot.username}`);
      return false;
    }

    const topic = this.news.nextTopicForBot(bot.id);
    const item = await this.news.fetchForRegion(region, topic, bot.id);
    if (!item) return false;

    const exists = await this.prisma.post.findUnique({
      where: { sourceUrl: item.sourceUrl },
      select: { id: true },
    });
    if (exists) return false;

    try {
      await this.posts.create(bot.id, item.content, item.media, item.sourceUrl);
      this.logger.log(`Posted [${region.name}/${item.topic}] ${item.title.slice(0, 50)}… (${item.media.length} media)`);
      return true;
    } catch (err) {
      this.logger.error(`Post failed for ${bot.username}: ${err instanceof Error ? err.message : err}`);
      return false;
    }
  }

  /** Admin: trigger a burst of real posts (still staggered internally) */
  async postForAllBots(trigger: 'manual' | 'seed' = 'manual') {
    await this.refreshBotQueue();
    let posted = 0;
    let failed = 0;

    for (const bot of this.botQueue) {
      const ok = await this.postRealNewsForBot(bot);
      if (ok) posted++;
      else failed++;
      await sleep(2000 + Math.random() * 3000);
    }

    this.logger.log(`[${trigger}] Burst done — ${posted} posted, ${failed} skipped/failed`);
    return { posted, failed };
  }
}

function sleep(ms: number) {
  return new Promise((r) => setTimeout(r, ms));
}
