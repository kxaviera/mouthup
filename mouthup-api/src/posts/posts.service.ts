import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, PostMood, SupportReactionType, ListingType, ListingStatus, RentPeriod } from '@prisma/client';
import { CreateListingDto } from './dto/create-listing.dto';
import { PrismaService } from '../prisma/prisma.service';
import { ModerationService } from '../moderation/moderation.service';
import { UsersService } from '../users/users.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { buildCursorPage } from '../common/dto/cursor-pagination.dto';
import { countWords, extractHashtags, MAX_POST_WORDS } from '../common/utils/post-text.util';

const postInclude = {
  author: {
    select: {
      username: true,
      screenName: true,
      avatarSeed: true,
      profession: true,
      accountType: true,
      city: true,
      isVerified: true,
    },
  },
  media: { orderBy: { sortOrder: 'asc' as const } },
  _count: { select: { likes: true, comments: true } },
} satisfies Prisma.PostInclude;

type PostWithDetails = Prisma.PostGetPayload<{ include: typeof postInclude }>;

@Injectable()
export class PostsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly moderation: ModerationService,
    private readonly users: UsersService,
    private readonly realtime: RealtimeGateway,
  ) {}

  private async blockedAuthorIds(viewerId?: string) {
    if (!viewerId) return [] as string[];
    const blocks = await this.users.getBlockedIdsForUser(viewerId);
    return blocks.map((b) => b.blockedId);
  }

  private parseHashtags(value: unknown): string[] {
    if (Array.isArray(value)) return value.map(String);
    if (typeof value === 'string') {
      try {
        const parsed = JSON.parse(value) as unknown;
        return Array.isArray(parsed) ? parsed.map(String) : [];
      } catch {
        return [];
      }
    }
    return [];
  }

  private mapPost(
    post: PostWithDetails,
    ctx: {
      savedIds?: Set<string>;
      likedIds?: Set<string>;
      supportByPost?: Map<string, SupportReactionType>;
    } = {},
  ) {
    return {
      id: post.id,
      title: post.title,
      author: post.author.username ?? 'Anonymous',
      authorScreenName: post.author.screenName ?? post.author.username ?? 'Anonymous',
      avatarSeed: post.author.avatarSeed,
      authorProfession: post.author.profession,
      authorAccountType: post.author.accountType,
      authorCity: post.author.city,
      authorIsVerified: post.author.isVerified,
      content: post.content,
      hashtags: this.parseHashtags(post.hashtags),
      mood: post.mood ?? null,
      listingType: post.listingType,
      listingStatus: post.listingStatus,
      price: post.price != null ? Number(post.price) : null,
      currency: post.currency,
      rentPeriod: post.rentPeriod,
      swapFor: post.swapFor,
      location: post.location,
      viewCount: post.viewCount,
      likeCount: post._count.likes,
      commentCount: post._count.comments,
      imageUrls: post.media.filter((m) => m.type === 'IMAGE').map((m) => m.url),
      videoUrls: post.media.filter((m) => m.type === 'VIDEO').map((m) => m.url),
      createdAt: post.createdAt,
      updatedAt: post.updatedAt,
      userSaved: ctx.savedIds?.has(post.id) ?? false,
      userLiked: ctx.likedIds?.has(post.id) ?? false,
      userSupportReaction: ctx.supportByPost?.get(post.id) ?? null,
    };
  }

  private broadcastFeedPost(mapped: ReturnType<PostsService['mapPost']>) {
    const city = (mapped.location as string | null) ?? (mapped.authorCity as string | null);
    this.realtime.emitNewFeedPost(mapped, city);
  }

  private broadcastFeedUpdate(mapped: ReturnType<PostsService['mapPost']>) {
    const city = (mapped.location as string | null) ?? (mapped.authorCity as string | null);
    this.realtime.emitFeedUpdated(mapped, city);
  }

  private async loadPostContext(viewerId: string | undefined, postIds: string[]) {
    if (!viewerId || postIds.length === 0) {
      return {
        savedIds: new Set<string>(),
        likedIds: new Set<string>(),
        supportByPost: new Map<string, SupportReactionType>(),
      };
    }
    const [saves, likes, supports] = await Promise.all([
      this.prisma.save.findMany({
        where: { userId: viewerId, postId: { in: postIds } },
        select: { postId: true },
      }),
      this.prisma.postLike.findMany({
        where: { userId: viewerId, postId: { in: postIds } },
        select: { postId: true },
      }),
      this.prisma.postSupportReaction.findMany({
        where: { userId: viewerId, postId: { in: postIds } },
        select: { postId: true, type: true },
      }),
    ]);
    return {
      savedIds: new Set(saves.map((s) => s.postId)),
      likedIds: new Set(likes.map((l) => l.postId)),
      supportByPost: new Map(supports.map((s) => [s.postId, s.type])),
    };
  }

  async feed(params: {
    cursor?: string;
    limit?: number;
    hashtag?: string;
    q?: string;
    listingType?: ListingType;
    city?: string;
    viewerId?: string;
  }) {
    const limit = Math.min(params.limit ?? 20, 50);
    const blockedIds = await this.blockedAuthorIds(params.viewerId);

    const where: Prisma.PostWhereInput = {
      deletedAt: null,
      authorId: blockedIds.length ? { notIn: blockedIds } : undefined,
      ...(params.listingType ? { listingType: params.listingType } : {}),
      ...(params.hashtag
        ? {
            content: {
              contains: `#${params.hashtag.toLowerCase().replace(/^#/, '')}`,
              mode: 'insensitive' as const,
            },
          }
        : {}),
      ...(params.q
        ? {
            OR: [
              { title: { contains: params.q, mode: 'insensitive' } },
              { content: { contains: params.q, mode: 'insensitive' } },
              { location: { contains: params.q, mode: 'insensitive' } },
            ],
          }
        : {}),
      ...(params.city
        ? {
            OR: [
              { location: { contains: params.city, mode: 'insensitive' } },
              { author: { city: { contains: params.city, mode: 'insensitive' } } },
            ],
          }
        : {}),
    };

    const posts = await this.prisma.post.findMany({
      where,
      take: limit + 1,
      ...(params.cursor ? { cursor: { id: params.cursor }, skip: 1 } : {}),
      orderBy: { createdAt: 'desc' },
      include: postInclude,
    });

    const ctx = await this.loadPostContext(
      params.viewerId,
      posts.map((p) => p.id),
    );

    const page = buildCursorPage(posts, limit);
    return {
      ...page,
      items: page.items.map((p) => this.mapPost(p, ctx)),
    };
  }

  async trendingHashtags(limit = 10) {
    const stats = await this.prisma.hashtagStat.findMany({
      take: limit,
      orderBy: { postCount: 'desc' },
    });
    return stats.map((s) => ({ tag: s.tag, count: s.postCount }));
  }

  async getById(id: string, viewerId?: string) {
    await this.prisma.post.updateMany({
      where: { id, deletedAt: null },
      data: { viewCount: { increment: 1 } },
    });

    const post = await this.prisma.post.findFirst({
      where: { id, deletedAt: null },
      include: postInclude,
    });
    if (!post) throw new NotFoundException('Post not found');

    const ctx = await this.loadPostContext(viewerId, [id]);
    return this.mapPost(post, ctx);
  }

  async createListing(authorId: string, dto: CreateListingDto) {
    const title = dto.title.trim();
    const content = dto.content.trim();
    if (title.length < 3) throw new BadRequestException('Title is too short');

    const combined = `${title}\n${content}`;
    const words = countWords(combined);
    if (words > MAX_POST_WORDS) {
      throw new BadRequestException(`Post exceeds ${MAX_POST_WORDS} words`);
    }

    const mod = await this.moderation.check(combined);
    if (!mod.allowed) throw new BadRequestException(mod.reason);

    const listingType = dto.listingType as ListingType;
    this.validateListingFields(listingType, dto);

    const author = await this.prisma.user.findUniqueOrThrow({
      where: { id: authorId },
      select: { accountType: true, profession: true, city: true },
    });

    if (listingType === 'SERVICE' && author.accountType !== 'SERVICE_PROVIDER') {
      throw new BadRequestException('Only service providers can post service offers');
    }

    const hashtags = extractHashtags(content);
    const tagForType = listingType.toLowerCase();
    if (!hashtags.includes(tagForType)) hashtags.unshift(tagForType);

    const post = await this.prisma.post.create({
      data: {
        authorId,
        title,
        content,
        listingType,
        listingStatus: 'OPEN',
        price: dto.price != null ? dto.price : null,
        currency: dto.currency ?? 'INR',
        rentPeriod: dto.rentPeriod as RentPeriod | undefined,
        swapFor: dto.swapFor?.trim() || null,
        location: dto.location?.trim() || author.city || null,
        hashtags: hashtags as unknown as Prisma.InputJsonValue,
        media: {
          create: (dto.media ?? []).map((m, i) => ({
            type: m.type,
            url: m.url,
            sortOrder: i,
          })),
        },
      },
      include: postInclude,
    });

    await this.updateHashtagStats(hashtags);
    const mapped = this.mapPost(post);
    this.broadcastFeedPost(mapped);
    return mapped;
  }

  private validateListingFields(listingType: ListingType, dto: CreateListingDto) {
    if (listingType === 'SWAP' && !dto.swapFor?.trim()) {
      throw new BadRequestException('Swap posts need swapFor — what you want in exchange');
    }
    if (listingType === 'RENT' && dto.price != null && !dto.rentPeriod) {
      throw new BadRequestException('Rent posts with a price need rentPeriod (DAY/WEEK/MONTH)');
    }
    if (listingType === 'GIVEAWAY' && dto.price != null && dto.price > 0) {
      throw new BadRequestException('Giveaway posts cannot have a price');
    }
  }

  async updateListingStatus(
    authorId: string,
    postId: string,
    status: 'OPEN' | 'CLOSED',
  ) {
    const post = await this.prisma.post.findFirst({
      where: { id: postId, deletedAt: null },
    });
    if (!post) throw new NotFoundException('Post not found');
    if (post.authorId !== authorId) throw new ForbiddenException();

    const updated = await this.prisma.post.update({
      where: { id: postId },
      data: { listingStatus: status as ListingStatus },
      include: postInclude,
    });
    const mapped = this.mapPost(updated);
    this.broadcastFeedUpdate(mapped);
    return mapped;
  }

  async toggleLike(userId: string, postId: string) {
    const post = await this.prisma.post.findFirst({
      where: { id: postId, deletedAt: null },
    });
    if (!post) throw new NotFoundException('Post not found');

    const existing = await this.prisma.postLike.findUnique({
      where: { userId_postId: { userId, postId } },
    });

    if (existing) {
      await this.prisma.postLike.delete({
        where: { userId_postId: { userId, postId } },
      });
      return { liked: false };
    }

    await this.prisma.postLike.create({ data: { userId, postId } });
    return { liked: true };
  }

  async create(
    authorId: string,
    content: string,
    media: { type: 'IMAGE' | 'VIDEO'; url: string }[] = [],
    sourceUrl?: string,
    mood?: string,
  ) {
    const words = countWords(content);
    if (words > MAX_POST_WORDS) {
      throw new BadRequestException(`Post exceeds ${MAX_POST_WORDS} words`);
    }

    const mod = await this.moderation.check(content);
    if (!mod.allowed) throw new BadRequestException(mod.reason);

    const hashtags = extractHashtags(content);
    const parsedMood = this.parseMood(mood);

    const post = await this.prisma.post.create({
      data: {
        authorId,
        content: content.trim(),
        hashtags: hashtags as unknown as Prisma.InputJsonValue,
        mood: parsedMood,
        sourceUrl,
        media: {
          create: media.map((m, i) => ({
            type: m.type,
            url: m.url,
            sortOrder: i,
          })),
        },
      },
      include: postInclude,
    });

    await this.updateHashtagStats(hashtags);
    const mapped = this.mapPost(post);
    this.broadcastFeedPost(mapped);
    return mapped;
  }

  async updatePost(authorId: string, postId: string, content: string) {
    const post = await this.prisma.post.findFirst({
      where: { id: postId, deletedAt: null },
    });
    if (!post) throw new NotFoundException('Post not found');
    if (post.authorId !== authorId) throw new ForbiddenException();

    const words = countWords(content);
    if (words > MAX_POST_WORDS) {
      throw new BadRequestException(`Post exceeds ${MAX_POST_WORDS} words`);
    }

    const mod = await this.moderation.check(content);
    if (!mod.allowed) throw new BadRequestException(mod.reason);

    const hashtags = extractHashtags(content);
    const updated = await this.prisma.post.update({
      where: { id: postId },
      data: { content: content.trim(), hashtags: hashtags as unknown as Prisma.InputJsonValue },
      include: postInclude,
    });

    await this.updateHashtagStats(hashtags);
    const mapped = this.mapPost(updated);
    this.broadcastFeedUpdate(mapped);
    return mapped;
  }

  async deletePost(authorId: string, postId: string) {
    const post = await this.prisma.post.findFirst({
      where: { id: postId },
      include: postInclude,
    });
    if (!post) throw new NotFoundException('Post not found');
    if (post.authorId !== authorId) throw new ForbiddenException();

    await this.prisma.post.update({
      where: { id: postId },
      data: { deletedAt: new Date() },
    });
    const city = post.location ?? post.author.city ?? null;
    this.realtime.emitFeedRemoved(postId, city);
    return { message: 'Post deleted' };
  }

  async toggleSave(userId: string, postId: string) {
    const post = await this.prisma.post.findFirst({
      where: { id: postId, deletedAt: null },
    });
    if (!post) throw new NotFoundException('Post not found');

    const existing = await this.prisma.save.findUnique({
      where: { userId_postId: { userId, postId } },
    });

    if (existing) {
      await this.prisma.save.delete({
        where: { userId_postId: { userId, postId } },
      });
      return { saved: false };
    }

    await this.prisma.save.create({ data: { userId, postId } });
    return { saved: true };
  }

  async savedPosts(userId: string, cursor?: string, limit = 20) {
    const take = Math.min(limit, 50);
    const saves = await this.prisma.save.findMany({
      where: { userId, post: { deletedAt: null } },
      take: take + 1,
      ...(cursor
        ? { cursor: { userId_postId: { userId, postId: cursor } }, skip: 1 }
        : {}),
      orderBy: { createdAt: 'desc' },
      include: {
        post: { include: postInclude },
      },
    });

    const hasMore = saves.length > take;
    const pageSaves = hasMore ? saves.slice(0, take) : saves;
    const ctx = await this.loadPostContext(
      userId,
      pageSaves.map((s) => s.postId),
    );

    return {
      items: pageSaves.map((s) => this.mapPost(s.post, ctx)),
      nextCursor: hasMore ? pageSaves[pageSaves.length - 1].postId : null,
      hasMore,
    };
  }

  async myPosts(authorId: string, cursor?: string, limit = 20) {
    const take = Math.min(limit, 50);
    const posts = await this.prisma.post.findMany({
      where: { authorId, deletedAt: null },
      take: take + 1,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      orderBy: { createdAt: 'desc' },
      include: postInclude,
    });

    const page = buildCursorPage(posts, take);
    const ctx = await this.loadPostContext(
      authorId,
      page.items.map((p) => p.id),
    );
    return { ...page, items: page.items.map((p) => this.mapPost(p, ctx)) };
  }

  async postsByUser(username: string, cursor?: string, limit = 20, viewerId?: string) {
    const user = await this.prisma.user.findUnique({ where: { username } });
    if (!user) throw new NotFoundException('User not found');
    return this.myPosts(user.id, cursor, limit);
  }

  async toggleSupportReaction(
    userId: string,
    postId: string,
    type: SupportReactionType,
  ) {
    const post = await this.prisma.post.findFirst({
      where: { id: postId, deletedAt: null },
    });
    if (!post) throw new NotFoundException('Post not found');

    const existing = await this.prisma.postSupportReaction.findUnique({
      where: { userId_postId: { userId, postId } },
    });

    if (existing?.type === type) {
      await this.prisma.postSupportReaction.delete({
        where: { userId_postId: { userId, postId } },
      });
      return { reaction: null };
    }

    await this.prisma.postSupportReaction.upsert({
      where: { userId_postId: { userId, postId } },
      create: { userId, postId, type },
      update: { type },
    });
    return { reaction: type };
  }

  private parseMood(value?: string): PostMood | undefined {
    if (!value) return undefined;
    const allowed: PostMood[] = [
      'ANXIOUS',
      'LOW',
      'ANGRY',
      'GOOD',
      'CONFUSED',
      'EXCITED',
    ];
    return allowed.includes(value as PostMood) ? (value as PostMood) : undefined;
  }

  private async updateHashtagStats(tags: string[]) {
    for (const tag of tags) {
      await this.prisma.hashtagStat.upsert({
        where: { tag },
        create: { tag, postCount: 1 },
        update: { postCount: { increment: 1 } },
      });
    }
  }
}
