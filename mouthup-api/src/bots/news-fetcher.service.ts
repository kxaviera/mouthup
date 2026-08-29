import { Injectable, Logger } from '@nestjs/common';
import Parser from 'rss-parser';
import { BOT_REGIONS, BotRegion } from './bot-regions';
import { localeForSlug } from './news-gl-codes';
import { MAX_POST_WORDS } from '../common/utils/post-text.util';

export type NewsTopic =
  | 'NEWS'
  | 'POLITICS'
  | 'WORLD'
  | 'BUSINESS'
  | 'TECHNOLOGY'
  | 'SCIENCE'
  | 'HEALTH'
  | 'SPORTS'
  | 'ENTERTAINMENT'
  | 'BOLLYWOOD'
  | 'HOLLYWOOD'
  | 'MUSIC'
  | 'GAMING'
  | 'FASHION'
  | 'FOOD'
  | 'TRAVEL'
  | 'CRIME'
  | 'EDUCATION'
  | 'CLIMATE'
  | 'CRYPTO';

export interface RealNewsItem {
  title: string;
  content: string;
  sourceUrl: string;
  media: { type: 'IMAGE' | 'VIDEO'; url: string }[];
  topic: NewsTopic;
}

/** Every bot rotates through the full topic list — no regional restrictions. */
const ALL_TOPICS: NewsTopic[] = [
  'NEWS',
  'POLITICS',
  'WORLD',
  'BUSINESS',
  'TECHNOLOGY',
  'SCIENCE',
  'HEALTH',
  'SPORTS',
  'ENTERTAINMENT',
  'BOLLYWOOD',
  'HOLLYWOOD',
  'MUSIC',
  'GAMING',
  'FASHION',
  'FOOD',
  'TRAVEL',
  'CRIME',
  'EDUCATION',
  'CLIMATE',
  'CRYPTO',
];

const TOPIC_TAGS: Record<NewsTopic, string[]> = {
  NEWS: ['#news', '#latest'],
  POLITICS: ['#politics', '#government'],
  WORLD: ['#world', '#breaking'],
  BUSINESS: ['#business', '#markets'],
  TECHNOLOGY: ['#tech', '#innovation'],
  SCIENCE: ['#science', '#discovery'],
  HEALTH: ['#health', '#wellness'],
  SPORTS: ['#sports', '#live'],
  ENTERTAINMENT: ['#entertainment', '#viral'],
  BOLLYWOOD: ['#bollywood', '#entertainment'],
  HOLLYWOOD: ['#hollywood', '#movies'],
  MUSIC: ['#music', '#entertainment'],
  GAMING: ['#gaming', '#esports'],
  FASHION: ['#fashion', '#style'],
  FOOD: ['#food', '#recipes'],
  TRAVEL: ['#travel', '#tourism'],
  CRIME: ['#crime', '#law'],
  EDUCATION: ['#education', '#schools'],
  CLIMATE: ['#climate', '#environment'],
  CRYPTO: ['#crypto', '#finance'],
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

  private readonly botTopicIndex = new Map<string, number>();

  /** Full topic rotation — same list for every bot worldwide. */
  allTopics(): NewsTopic[] {
    return ALL_TOPICS;
  }

  nextTopicForBot(botId: string): NewsTopic {
    const idx = this.botTopicIndex.get(botId) ?? 0;
    const topic = ALL_TOPICS[idx % ALL_TOPICS.length];
    this.botTopicIndex.set(botId, idx + 1);
    return topic;
  }

  buildFeedUrl(region: BotRegion, topic: NewsTopic): string {
    const { gl, hl } = localeForSlug(region.slug, region.country);
    const ceid = `${gl}:${hl.split('-')[0]}`;
    const q = encodeURIComponent(this.searchQuery(region, topic));
    return `https://news.google.com/rss/search?q=${q}&hl=${hl}&gl=${gl}&ceid=${ceid}`;
  }

  private searchQuery(region: BotRegion, topic: NewsTopic): string {
    const place = region.name;
    const queries: Record<NewsTopic, string> = {
      NEWS: `${place} news when:1d`,
      POLITICS: `${place} politics when:2d`,
      WORLD: `${place} world news when:2d`,
      BUSINESS: `${place} business economy when:2d`,
      TECHNOLOGY: `${place} technology when:2d`,
      SCIENCE: `${place} science when:2d`,
      HEALTH: `${place} health when:2d`,
      SPORTS: `${place} sports when:2d`,
      ENTERTAINMENT: `${place} entertainment celebrity when:2d`,
      BOLLYWOOD: `${place} Bollywood when:2d`,
      HOLLYWOOD: `${place} Hollywood movies when:2d`,
      MUSIC: `${place} music when:2d`,
      GAMING: `${place} gaming esports when:2d`,
      FASHION: `${place} fashion when:2d`,
      FOOD: `${place} food restaurant when:2d`,
      TRAVEL: `${place} travel tourism when:2d`,
      CRIME: `${place} crime when:2d`,
      EDUCATION: `${place} education schools when:2d`,
      CLIMATE: `${place} climate environment when:2d`,
      CRYPTO: `${place} cryptocurrency bitcoin when:2d`,
    };
    return queries[topic];
  }

  async fetchForRegion(
    region: BotRegion,
    topic: NewsTopic,
    botId?: string,
  ): Promise<RealNewsItem | null> {
    const chosenTopic = topic;
    const feedUrl = this.buildFeedUrl(region, chosenTopic);

    try {
      const feed = await this.parser.parseURL(feedUrl);
      const items = (feed.items ?? []).slice(0, 15);
      if (items.length === 0) return null;

      for (const item of items) {
        if (!item.title || !item.link) continue;
        const parsed = await this.buildNewsItem(item, region, chosenTopic);
        if (parsed) return parsed;
      }
      return null;
    } catch (err) {
      this.logger.warn(`RSS fetch failed for ${region.name} [${chosenTopic}]: ${err instanceof Error ? err.message : err}`);
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
    let content = this.composePostBody(title, snippet);
    content = `${content}\n\n${tags}`;
    content = this.trimWords(content, MAX_POST_WORDS);

    const media = await this.extractMedia(item, link);

    return { title, content, sourceUrl: link, media, topic };
  }

  private async extractMedia(
    item: Parser.Item,
    pageUrl: string,
  ): Promise<RealNewsItem['media']> {
    const media: RealNewsItem['media'] = [];
    const seen = new Set<string>();

    const push = (type: 'IMAGE' | 'VIDEO', url: string | null | undefined) => {
      if (!url || !url.startsWith('http') || seen.has(url)) return;
      seen.add(url);
      media.push({ type, url });
    };

    const fromItem = this.extractMediaFromItem(item);
    for (const m of fromItem) push(m.type, m.url);

    const pageMedia = await this.fetchPageMedia(pageUrl);
    if (pageMedia.video) push('VIDEO', pageMedia.video);
    if (pageMedia.image) push('IMAGE', pageMedia.image);

    const html = item.content ?? item.summary ?? '';
    const ytId = this.extractYoutubeId(html) ?? this.extractYoutubeId(pageUrl);
    if (ytId) {
      push('IMAGE', `https://img.youtube.com/vi/${ytId}/hqdefault.jpg`);
    }

    return media.slice(0, 4);
  }

  private extractMediaFromItem(item: Parser.Item): RealNewsItem['media'] {
    const out: RealNewsItem['media'] = [];

    const enclosure = item.enclosure;
    if (enclosure?.url) {
      if (enclosure.type?.startsWith('video/') && this.isPlayableVideoUrl(enclosure.url)) {
        out.push({ type: 'VIDEO', url: enclosure.url });
      } else if (enclosure.type?.startsWith('image/')) {
        out.push({ type: 'IMAGE', url: enclosure.url });
      }
    }

    const mediaContent = (item as Record<string, unknown>)['media:content'] as
      | { $?: { url?: string; type?: string; medium?: string } }
      | undefined;
    const mc = mediaContent?.$;
    if (mc?.url) {
      if (mc.type?.startsWith('video/') || mc.medium === 'video') {
        if (this.isPlayableVideoUrl(mc.url)) out.push({ type: 'VIDEO', url: mc.url });
      } else if (mc.type?.startsWith('image/') || mc.medium === 'image') {
        out.push({ type: 'IMAGE', url: mc.url });
      }
    }

    const mediaThumb = (item as Record<string, unknown>)['media:thumbnail'] as
      | { $?: { url?: string } }
      | undefined;
    if (mediaThumb?.$?.url) out.push({ type: 'IMAGE', url: mediaThumb.$.url });

    const html = item.content ?? item.summary ?? '';
    const imgMatch = html.match(/src=["']([^"']+\.(?:jpg|jpeg|png|webp|gif)[^"']*)["']/i);
    if (imgMatch?.[1]) out.push({ type: 'IMAGE', url: imgMatch[1] });

    const videoMatch = html.match(/src=["']([^"']+\.(?:mp4|webm|m3u8)[^"']*)["']/i);
    if (videoMatch?.[1] && this.isPlayableVideoUrl(videoMatch[1])) {
      out.push({ type: 'VIDEO', url: videoMatch[1] });
    }

    return out;
  }

  private async fetchPageMedia(pageUrl: string): Promise<{ image?: string; video?: string }> {
    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 7000);
      const res = await fetch(pageUrl, {
        signal: controller.signal,
        redirect: 'follow',
        headers: {
          'User-Agent': 'MouthUpBot/1.0 (news aggregator)',
          Accept: 'text/html',
        },
      });
      clearTimeout(timeout);
      if (!res.ok) return {};
      const html = (await res.text()).slice(0, 80_000);

      const imagePatterns = [
        /property=["']og:image(?::url)?["'][^>]*content=["']([^"']+)["']/i,
        /content=["']([^"']+)["'][^>]*property=["']og:image(?::url)?["']/i,
        /name=["']twitter:image(?::src)?["'][^>]*content=["']([^"']+)["']/i,
      ];
      const videoPatterns = [
        /property=["']og:video(?::url)?["'][^>]*content=["']([^"']+)["']/i,
        /content=["']([^"']+)["'][^>]*property=["']og:video(?::url)?["']/i,
        /property=["']og:video:secure_url["'][^>]*content=["']([^"']+)["']/i,
      ];

      let image: string | undefined;
      for (const re of imagePatterns) {
        const m = html.match(re);
        if (m?.[1]?.startsWith('http')) {
          image = m[1];
          break;
        }
      }

      let video: string | undefined;
      for (const re of videoPatterns) {
        const m = html.match(re);
        if (m?.[1]?.startsWith('http') && this.isPlayableVideoUrl(m[1])) {
          video = m[1];
          break;
        }
      }

      if (!video) {
        const mp4 = html.match(/https?:\/\/[^"'\s]+\.mp4[^"'\s]*/i);
        if (mp4?.[0] && this.isPlayableVideoUrl(mp4[0])) video = mp4[0];
      }

      return { image, video };
    } catch {
      return {};
    }
  }

  private isPlayableVideoUrl(url: string): boolean {
    if (!url.startsWith('http')) return false;
    if (/youtube\.com|youtu\.be|vimeo\.com|dailymotion\.com|facebook\.com\/watch/i.test(url)) {
      return false;
    }
    return /\.(mp4|webm|m3u8|mov)(\?|$)/i.test(url) || /\/video\/|video\.|\.mp4/i.test(url);
  }

  private extractYoutubeId(text: string): string | null {
    const patterns = [
      /youtube\.com\/watch\?v=([\w-]{11})/i,
      /youtu\.be\/([\w-]{11})/i,
      /youtube\.com\/embed\/([\w-]{11})/i,
    ];
    for (const re of patterns) {
      const m = text.match(re);
      if (m?.[1]) return m[1];
    }
    return null;
  }

  private composePostBody(title: string, snippet: string): string {
    if (!snippet) return title;

    const titleKey = this.normalizeForCompare(title);
    const snippetKey = this.normalizeForCompare(snippet);
    if (snippetKey === titleKey) return title;

    const titleWithoutSource = title.replace(/\s[-–—|]\s[^-–—|]+$/, '').trim();
    if (this.normalizeForCompare(titleWithoutSource) === snippetKey) return title;

    if (
      snippetKey.startsWith(titleKey) ||
      titleKey.startsWith(snippetKey) ||
      snippetKey.includes(titleKey) ||
      titleKey.includes(snippetKey)
    ) {
      return title.length >= snippet.length ? title : snippet;
    }

    return `${title}\n\n${snippet}`;
  }

  private normalizeForCompare(text: string): string {
    return text
      .toLowerCase()
      .replace(/[^\p{L}\p{N}\s]/gu, '')
      .replace(/\s+/g, ' ')
      .trim();
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
