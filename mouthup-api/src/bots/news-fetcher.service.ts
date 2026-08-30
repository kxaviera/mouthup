import { Injectable, Logger } from '@nestjs/common';
import Parser from 'rss-parser';
import { BOT_REGIONS, BotRegion } from './bot-regions';
import { localeForSlug } from './news-gl-codes';
import { MAX_POST_WORDS } from '../common/utils/post-text.util';

export type NewsTopic =
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
  | 'EDUCATION';

export interface RealNewsItem {
  title: string;
  content: string;
  sourceUrl: string;
  media: { type: 'IMAGE' | 'VIDEO'; url: string }[];
  topic: NewsTopic;
}

/** Bots only post uplifting topics — no news, politics, crime, or doom. */
const POSITIVE_TOPICS: NewsTopic[] = [
  'SPORTS',
  'ENTERTAINMENT',
  'BOLLYWOOD',
  'HOLLYWOOD',
  'MUSIC',
  'GAMING',
  'FASHION',
  'FOOD',
  'TRAVEL',
  'HEALTH',
  'SCIENCE',
  'TECHNOLOGY',
  'EDUCATION',
];

/** Block accidents, politics, violence, disasters, and other negative headlines. */
const NEGATIVE_HEADLINE =
  /\b(death|deaths|died|die|dies|kill|killed|kills|murder|suicide|assault|rape|abuse|terror|terrorist|bomb|bombing|shooting|shot dead|gunman|stabb|war|airstrike|missile|invasion|conflict|casualt|hostage|kidnap|accident|crash|crashes|crashed|collision|derail|wreck|fire kills|deadly|fatal|fatality|injured in|politic|election|parliament|congress|minister|senator|government|democrat|republican|vote|ballot|scandal|corruption|fraud|scam|arrest|arrested|charged with|convict|prison|jail|crime|criminal|robbery|theft|murder|disaster|earthquake|tsunami|flood|flooding|hurricane|tornado|cyclone|wildfire|landslide|outbreak|pandemic|layoff|layoffs|recession|bankrupt|crisis|protest|riot|clash|violence|violent|mourn|funeral|condolence|slump|plunge|tumble|losses|crypto crash|bitcoin crash|climate crisis|extinction|pollution crisis)\b/i;

const EXCLUDE_FROM_SEARCH =
  ' -death -kill -murder -accident -crash -war -attack -crime -arrest -scandal -disaster -protest -politics -election -suicide -shooting -fatal -deadly';

const TOPIC_TAGS: Record<NewsTopic, string[]> = {
  TECHNOLOGY: ['#tech', '#innovation', '#goodvibes'],
  SCIENCE: ['#science', '#discovery', '#goodvibes'],
  HEALTH: ['#health', '#wellness', '#goodvibes'],
  SPORTS: ['#sports', '#highlights', '#goodvibes'],
  ENTERTAINMENT: ['#entertainment', '#viral', '#goodvibes'],
  BOLLYWOOD: ['#bollywood', '#entertainment', '#goodvibes'],
  HOLLYWOOD: ['#hollywood', '#movies', '#goodvibes'],
  MUSIC: ['#music', '#entertainment', '#goodvibes'],
  GAMING: ['#gaming', '#fun', '#goodvibes'],
  FASHION: ['#fashion', '#style', '#goodvibes'],
  FOOD: ['#food', '#recipes', '#goodvibes'],
  TRAVEL: ['#travel', '#tourism', '#goodvibes'],
  EDUCATION: ['#education', '#inspiration', '#goodvibes'],
};

@Injectable()
export class NewsFetcherService {
  private readonly logger = new Logger(NewsFetcherService.name);
  private readonly parser = new Parser({
    timeout: 15000,
    headers: {
      'User-Agent': 'MouthUpBot/1.0 (news aggregator; +https://mouthup.app)',
    },
    customFields: {
      item: [
        ['media:content', 'mediaContents', { keepArray: true }],
        ['media:thumbnail', 'mediaThumbnails', { keepArray: true }],
      ],
    },
  });

  private readonly botTopicIndex = new Map<string, number>();

  /** Uplifting topics only — bots spread good vibes. */
  allTopics(): NewsTopic[] {
    return POSITIVE_TOPICS;
  }

  nextTopicForBot(botId: string): NewsTopic {
    const idx = this.botTopicIndex.get(botId) ?? 0;
    const topic = POSITIVE_TOPICS[idx % POSITIVE_TOPICS.length];
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
      TECHNOLOGY: `${place} technology innovation launch${EXCLUDE_FROM_SEARCH} when:2d`,
      SCIENCE: `${place} science discovery space breakthrough${EXCLUDE_FROM_SEARCH} when:2d`,
      HEALTH: `${place} wellness fitness healthy living tips${EXCLUDE_FROM_SEARCH} when:2d`,
      SPORTS: `${place} sports win celebration highlights${EXCLUDE_FROM_SEARCH} when:2d`,
      ENTERTAINMENT: `${place} entertainment feel good viral${EXCLUDE_FROM_SEARCH} when:2d`,
      BOLLYWOOD: `${place} Bollywood celebration photos${EXCLUDE_FROM_SEARCH} when:2d`,
      HOLLYWOOD: `${place} Hollywood movies trailer premiere${EXCLUDE_FROM_SEARCH} when:2d`,
      MUSIC: `${place} music festival concert video${EXCLUDE_FROM_SEARCH} when:2d`,
      GAMING: `${place} gaming fun trailer gameplay${EXCLUDE_FROM_SEARCH} when:2d`,
      FASHION: `${place} fashion style photos${EXCLUDE_FROM_SEARCH} when:2d`,
      FOOD: `${place} food recipes delicious photos${EXCLUDE_FROM_SEARCH} when:2d`,
      TRAVEL: `${place} travel beautiful destinations photos${EXCLUDE_FROM_SEARCH} when:2d`,
      EDUCATION: `${place} students achievement inspiration${EXCLUDE_FROM_SEARCH} when:2d`,
    };
    return queries[topic];
  }

  /** Reject negative, political, or distressing headlines before posting. */
  isPositiveContent(title: string, snippet = ''): boolean {
    const text = `${title} ${snippet}`.trim();
    if (!text) return false;
    return !NEGATIVE_HEADLINE.test(text);
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

      // Prefer RSS items that already carry thumbnails (fast path).
      for (const item of items) {
        if (!item.title || !item.link) continue;
        if (!this.isPositiveContent(item.title, item.contentSnippet ?? '')) continue;
        if (this.extractMediaFromItem(item).length === 0) continue;
        const parsed = await this.buildNewsItem(item, region, chosenTopic);
        if (parsed?.media.length) return parsed;
      }

      // Fetch article pages for a few candidates to pull og:image / video.
      const mediaCandidates: RealNewsItem[] = [];
      for (const item of items.slice(0, 8)) {
        if (!item.title || !item.link) continue;
        if (!this.isPositiveContent(item.title, item.contentSnippet ?? '')) continue;
        const parsed = await this.buildNewsItem(item, region, chosenTopic);
        if (parsed?.media.length) mediaCandidates.push(parsed);
      }
      if (mediaCandidates.length > 0) {
        return mediaCandidates[Math.floor(Math.random() * mediaCandidates.length)];
      }

      // Positive text-only fallback (rare).
      for (const item of items.slice(0, 5)) {
        if (!item.title || !item.link) continue;
        if (!this.isPositiveContent(item.title, item.contentSnippet ?? '')) continue;
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

    if (!this.isPositiveContent(title, snippet)) return null;

    const regionTag = `#${region.name.replace(/\s+/g, '')}`;
    const tags = [...TOPIC_TAGS[topic], regionTag, '#goodvibes'].join(' ');
    let content = this.composePostBody(title, snippet);
    content = `${content}\n\n${tags}`;
    content = this.trimWords(content, MAX_POST_WORDS);

    const media = await this.extractMedia(item, link, title);

    return { title, content, sourceUrl: link, media, topic };
  }

  private async extractMedia(
    item: Parser.Item,
    pageUrl: string,
    title: string,
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
      push('VIDEO', `https://www.youtube.com/watch?v=${ytId}`);
      push('IMAGE', `https://img.youtube.com/vi/${ytId}/hqdefault.jpg`);
    }

    if (media.length === 0) {
      const wikiImage = await this.fetchWikiThumbnail(title);
      if (wikiImage) push('IMAGE', wikiImage);
    }

    return media.slice(0, 4);
  }

  private async fetchWikiThumbnail(title: string): Promise<string | undefined> {
    const slug = title
      .replace(/\s[-–—|]\s[^-–—|]+$/, '')
      .trim()
      .replace(/\s+/g, '_');
    if (!slug) return undefined;

    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 5000);
      const res = await fetch(
        `https://en.wikipedia.org/api/rest_v1/page/summary/${encodeURIComponent(slug)}`,
        {
          signal: controller.signal,
          headers: { Accept: 'application/json', 'User-Agent': 'MouthUpBot/1.0' },
        },
      );
      clearTimeout(timeout);
      if (!res.ok) return undefined;
      const data = (await res.json()) as { thumbnail?: { source?: string } };
      const url = data.thumbnail?.source;
      return url?.startsWith('http') ? url : undefined;
    } catch {
      return undefined;
    }
  }

  private extractMediaFromItem(item: Parser.Item): RealNewsItem['media'] {
    const out: RealNewsItem['media'] = [];
    const seen = new Set<string>();
    const push = (type: 'IMAGE' | 'VIDEO', url: string | null | undefined) => {
      if (!url || !url.startsWith('http') || seen.has(url) || !this.isLikelyArticleImage(url)) return;
      seen.add(url);
      out.push({ type, url });
    };

    const enclosure = item.enclosure;
    if (enclosure?.url) {
      if (enclosure.type?.startsWith('video/') && this.isPlayableVideoUrl(enclosure.url)) {
        push('VIDEO', enclosure.url);
      } else if (enclosure.type?.startsWith('image/')) {
        push('IMAGE', enclosure.url);
      }
    }

    const raw = item as Record<string, unknown>;
    const mediaContents = raw['mediaContents'] as
      | { $?: { url?: string; type?: string; medium?: string } }[]
      | undefined;
    if (Array.isArray(mediaContents)) {
      for (const entry of mediaContents) {
        const mc = entry?.$;
        if (!mc?.url) continue;
        if (mc.type?.startsWith('video/') || mc.medium === 'video') {
          if (this.isPlayableVideoUrl(mc.url) || this.extractYoutubeId(mc.url)) {
            push('VIDEO', mc.url);
          }
        } else if (mc.type?.startsWith('image/') || mc.medium === 'image') {
          push('IMAGE', mc.url);
        }
      }
    }

    const mediaThumbnails = raw['mediaThumbnails'] as { $?: { url?: string } }[] | undefined;
    if (Array.isArray(mediaThumbnails)) {
      for (const entry of mediaThumbnails) {
        push('IMAGE', entry?.$?.url);
      }
    }

    const mediaContent = raw['media:content'] as
      | { $?: { url?: string; type?: string; medium?: string } }
      | undefined;
    const mc = mediaContent?.$;
    if (mc?.url) {
      if (mc.type?.startsWith('video/') || mc.medium === 'video') {
        if (this.isPlayableVideoUrl(mc.url) || this.extractYoutubeId(mc.url)) {
          push('VIDEO', mc.url);
        }
      } else if (mc.type?.startsWith('image/') || mc.medium === 'image') {
        push('IMAGE', mc.url);
      }
    }

    const mediaThumb = raw['media:thumbnail'] as { $?: { url?: string } } | undefined;
    if (mediaThumb?.$?.url) push('IMAGE', mediaThumb.$.url);

    const html = item.content ?? item.summary ?? item.contentSnippet ?? '';
    for (const match of html.matchAll(/<img[^>]+src=["']([^"']+)["']/gi)) {
      push('IMAGE', match[1]);
    }

    const imgMatch = html.match(/src=["']([^"']+\.(?:jpg|jpeg|png|webp|gif)[^"']*)["']/i);
    if (imgMatch?.[1]) push('IMAGE', imgMatch[1]);

    const videoMatch = html.match(/src=["']([^"']+\.(?:mp4|webm|m3u8)[^"']*)["']/i);
    if (videoMatch?.[1] && this.isPlayableVideoUrl(videoMatch[1])) {
      push('VIDEO', videoMatch[1]);
    }

    const ytId = this.extractYoutubeId(html);
    if (ytId) {
      push('VIDEO', `https://www.youtube.com/watch?v=${ytId}`);
      push('IMAGE', `https://img.youtube.com/vi/${ytId}/hqdefault.jpg`);
    }

    return out;
  }

  private isLikelyArticleImage(url: string): boolean {
    if (/logo|icon|favicon|pixel|1x1|avatar|badge|spacer|tracking/i.test(url)) return false;
    return true;
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
      const html = (await res.text()).slice(0, 120_000);

      const imagePatterns = [
        /property=["']og:image(?::url)?["'][^>]*content=["']([^"']+)["']/i,
        /content=["']([^"']+)["'][^>]*property=["']og:image(?::url)?["']/i,
        /name=["']twitter:image(?::src)?["'][^>]*content=["']([^"']+)["']/i,
        /"thumbnailUrl"\s*:\s*"([^"]+)"/i,
        /"image"\s*:\s*"([^"]+\.(?:jpg|jpeg|png|webp)[^"]*)"/i,
        /<link[^>]+rel=["']image_src["'][^>]+href=["']([^"']+)["']/i,
      ];
      const videoPatterns = [
        /property=["']og:video(?::url)?["'][^>]*content=["']([^"']+)["']/i,
        /content=["']([^"']+)["'][^>]*property=["']og:video(?::url)?["']/i,
        /property=["']og:video:secure_url["'][^>]*content=["']([^"']+)["']/i,
      ];

      let image: string | undefined;
      for (const re of imagePatterns) {
        const m = html.match(re);
        if (m?.[1]?.startsWith('http') && this.isLikelyArticleImage(m[1])) {
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
      return true;
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
