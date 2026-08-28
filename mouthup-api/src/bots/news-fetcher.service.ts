import { Injectable, Logger } from '@nestjs/common';
import Parser from 'rss-parser';
import { BOT_REGIONS, BotRegion } from './bot-regions';
import { localeForSlug } from './news-gl-codes';
import { MAX_POST_WORDS } from '../common/utils/post-text.util';

export type NewsTopic =
  | 'WORLD'
  | 'NATION'
  | 'BUSINESS'
  | 'TECHNOLOGY'
  | 'ENTERTAINMENT'
  | 'SCIENCE'
  | 'SPORTS'
  | 'HEALTH';

export interface RealNewsItem {
  title: string;
  content: string;
  sourceUrl: string;
  media: { type: 'IMAGE' | 'VIDEO'; url: string }[];
  topic: NewsTopic;
}

const TOPICS: NewsTopic[] = [
  'WORLD',
  'NATION',
  'BUSINESS',
  'TECHNOLOGY',
  'ENTERTAINMENT',
  'SCIENCE',
  'SPORTS',
  'HEALTH',
];

const TOPIC_TAGS: Record<NewsTopic, string[]> = {
  WORLD: ['#world', '#breaking'],
  NATION: ['#politics', '#news'],
  BUSINESS: ['#business', '#markets'],
  TECHNOLOGY: ['#tech', '#innovation'],
  ENTERTAINMENT: ['#entertainment', '#viral'],
  SCIENCE: ['#science', '#discovery'],
  SPORTS: ['#sports', '#live'],
  HEALTH: ['#health', '#wellness'],
};

@Injectable()
export class NewsFetcherService {
  private readonly logger = new Logger(NewsFetcherService.name);
  private readonly parser = new Parser({
    timeout: 15000,
    headers: {
      'User-Agent': 'MouthUpBot/1.0 (news aggregator; +https://mouthup.app)',
    },
  });

  private topicIndex = 0;

  nextTopic(): NewsTopic {
    const topic = TOPICS[this.topicIndex % TOPICS.length];
    this.topicIndex++;
    return topic;
  }

  buildFeedUrl(region: BotRegion, topic: NewsTopic): string {
    const { gl, hl } = localeForSlug(region.slug, region.country);
    const ceid = `${gl}:${hl.split('-')[0]}`;

    if (region.country === 'USA') {
      const q = encodeURIComponent(`${region.name} news when:1d`);
      return `https://news.google.com/rss/search?q=${q}&hl=${hl}&gl=${gl}&ceid=${ceid}`;
    }

    const topicPath = topic === 'NATION' ? 'WORLD' : topic;
    return `https://news.google.com/rss/headlines/section/topic/${topicPath}?hl=${hl}&gl=${gl}&ceid=${ceid}`;
  }

  async fetchForRegion(region: BotRegion, topic?: NewsTopic): Promise<RealNewsItem | null> {
    const chosenTopic = topic ?? this.nextTopic();
    const feedUrl = this.buildFeedUrl(region, chosenTopic);

    try {
      const feed = await this.parser.parseURL(feedUrl);
      const items = (feed.items ?? []).slice(0, 12);
      if (items.length === 0) return null;

      for (const item of items) {
        if (!item.title || !item.link) continue;
        const parsed = await this.buildNewsItem(item, region, chosenTopic);
        if (parsed) return parsed;
      }
      return null;
    } catch (err) {
      this.logger.warn(`RSS fetch failed for ${region.name}: ${err instanceof Error ? err.message : err}`);
      return null;
    }
  }

  resolveRegion(bot: { region: string | null; username: string | null; avatarSeed?: string | null }) {
    const byName = BOT_REGIONS.find((r) => r.name === bot.region);
    if (byName) return byName;
    const slug = bot.avatarSeed ?? bot.username?.toLowerCase() ?? '';
    return BOT_REGIONS.find((r) => r.slug === slug || r.username === bot.username);
  }

  private async buildNewsItem(
    item: Parser.Item,
    region: BotRegion,
    topic: NewsTopic,
  ): Promise<RealNewsItem | null> {
    const title = this.cleanText(item.title ?? '');
    const link = item.link ?? '';
    if (!title || !link) return null;

    const snippet = this.cleanText(
      item.contentSnippet ?? item.summary ?? item.content ?? '',
    ).slice(0, 280);

    const regionTag = `#${region.name.replace(/\s+/g, '')}`;
    const tags = [...TOPIC_TAGS[topic], regionTag, '#latest'].join(' ');
    let content = snippet ? `${title}\n\n${snippet}` : title;
    content = `${content}\n\n${tags}`;
    content = this.trimWords(content, MAX_POST_WORDS);

    const imageUrl = this.extractImageFromItem(item) ?? (await this.fetchOgImage(link));
    const media: RealNewsItem['media'] = imageUrl
      ? [{ type: 'IMAGE', url: imageUrl }]
      : [];

    return { title, content, sourceUrl: link, media, topic };
  }

  private async fetchOgImage(pageUrl: string): Promise<string | null> {
    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 6000);
      const res = await fetch(pageUrl, {
        signal: controller.signal,
        redirect: 'follow',
        headers: {
          'User-Agent': 'MouthUpBot/1.0 (news aggregator)',
          Accept: 'text/html',
        },
      });
      clearTimeout(timeout);
      if (!res.ok) return null;
      const html = (await res.text()).slice(0, 50_000);
      const patterns = [
        /property=["']og:image(?::url)?["'][^>]*content=["']([^"']+)["']/i,
        /content=["']([^"']+)["'][^>]*property=["']og:image(?::url)?["']/i,
        /name=["']twitter:image["'][^>]*content=["']([^"']+)["']/i,
      ];
      for (const re of patterns) {
        const m = html.match(re);
        if (m?.[1]?.startsWith('http')) return m[1];
      }
      return null;
    } catch {
      return null;
    }
  }

  private extractImageFromItem(item: Parser.Item): string | null {
    const enclosure = item.enclosure;
    if (enclosure?.url && enclosure.type?.startsWith('image/')) {
      return enclosure.url;
    }

    const mediaContent = (item as Record<string, unknown>)['media:content'] as
      | { $?: { url?: string; type?: string } }
      | undefined;
    if (mediaContent?.$?.url && mediaContent.$?.type?.startsWith('image/')) {
      return mediaContent.$.url;
    }

    const mediaThumb = (item as Record<string, unknown>)['media:thumbnail'] as
      | { $?: { url?: string } }
      | undefined;
    if (mediaThumb?.$?.url) return mediaThumb.$.url;

    const html = item.content ?? item.summary ?? '';
    const match = html.match(/src=["']([^"']+\.(?:jpg|jpeg|png|webp|gif)[^"']*)["']/i);
    return match?.[1] ?? null;
  }

  private cleanText(text: string): string {
    return text
      .replace(/<[^>]+>/g, ' ')
      .replace(/&nbsp;/g, ' ')
      .replace(/&amp;/g, '&')
      .replace(/&quot;/g, '"')
      .replace(/\s+/g, ' ')
      .trim();
  }

  private trimWords(text: string, maxWords: number): string {
    const words = text.trim().split(/\s+/);
    if (words.length <= maxWords) return text.trim();
    return words.slice(0, maxWords).join(' ') + '…';
  }
}
