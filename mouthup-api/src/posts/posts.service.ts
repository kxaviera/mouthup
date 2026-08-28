import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ModerationService } from '../moderation/moderation.service';
import { UsersService } from '../users/users.service';
import { buildCursorPage } from '../common/dto/cursor-pagination.dto';
import { countWords, extractHashtags, MAX_POST_WORDS } from '../common/utils/post-text.util';

@Injectable()
export class PostsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly moderation: ModerationService,
    private readonly users: UsersService,
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
    post: Prisma.PostGetPayload<{
      include: {
        author: { select: { username: true; avatarSeed: true } };
        media: true;
      };
    }>,
    savedPostIds?: Set<string>,
  ) {
    return {
      id: post.id,
      author: post.author.username ?? 'Anonymous',
      avatarSeed: post.author.avatarSeed,
      content: post.content,
      hashtags: this.parseHashtags(post.hashtags),
      imageUrls: post.media.filter((m) => m.type === 'IMAGE').map((m) => m.url),
      videoUrls: post.media.filter((m) => m.type === 'VIDEO').map((m) => m.url),
      createdAt: post.createdAt,
      updatedAt: post.updatedAt,
      userSaved: savedPostIds?.has(post.id) ?? false,
    };
  }

  async feed(params: {
    cursor?: string;
    limit?: number;
    hashtag?: string;
    viewerId?: string;
  }) {
    const limit = Math.min(params.limit ?? 20, 50);
    const blockedIds = await this.blockedAuthorIds(params.viewerId);

    const where: Prisma.PostWhereInput = {
      deletedAt: null,
      authorId: blockedIds.length ? { notIn: blockedIds } : undefined,
      ...(params.hashtag
        ? {
            content: {
              contains: `#${params.hashtag.toLowerCase().replace(/^#/, '')}`,
              mode: 'insensitive' as const,
            },
          }
        : {}),
    };

    const posts = await this.prisma.post.findMany({
      where,
      take: limit + 1,
      ...(params.cursor ? { cursor: { id: params.cursor }, skip: 1 } : {}),
      orderBy: { createdAt: 'desc' },
      include: {
        author: { select: { username: true, avatarSeed: true } },
        media: { orderBy: { sortOrder: 'asc' } },
      },
    });

    let savedIds = new Set<string>();
    if (params.viewerId) {
      const saves = await this.prisma.save.findMany({
        where: {
          userId: params.viewerId,
          postId: { in: posts.map((p) => p.id) },
        },
        select: { postId: true },
      });
      savedIds = new Set(saves.map((s) => s.postId));
    }

    const page = buildCursorPage(posts, limit);
    return {
      ...page,
      items: page.items.map((p) => this.mapPost(p, savedIds)),
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
    const post = await this.prisma.post.findFirst({
      where: { id, deletedAt: null },
      include: {
        author: { select: { username: true, avatarSeed: true } },
        media: { orderBy: { sortOrder: 'asc' } },
      },
    });
    if (!post) throw new NotFoundException('Post not found');

    let userSaved = false;
    if (viewerId) {
      const save = await this.prisma.save.findUnique({
        where: { userId_postId: { userId: viewerId, postId: id } },
      });
      userSaved = !!save;
    }

    return this.mapPost(post, new Set(userSaved ? [id] : []));
  }

  async create(
    authorId: string,
    content: string,
    media: { type: 'IMAGE' | 'VIDEO'; url: string }[] = [],
    sourceUrl?: string,
  ) {
    const words = countWords(content);
    if (words > MAX_POST_WORDS) {
      throw new BadRequestException(`Post exceeds ${MAX_POST_WORDS} words`);
    }

    const mod = await this.moderation.check(content);
    if (!mod.allowed) throw new BadRequestException(mod.reason);

    const hashtags = extractHashtags(content);

    const post = await this.prisma.post.create({
      data: {
        authorId,
        content: content.trim(),
        hashtags: hashtags as unknown as Prisma.InputJsonValue,
        sourceUrl,
        media: {
          create: media.map((m, i) => ({
            type: m.type,
            url: m.url,
            sortOrder: i,
          })),
        },
      },
      include: {
        author: { select: { username: true, avatarSeed: true } },
        media: true,
      },
    });

    await this.updateHashtagStats(hashtags);
    return this.mapPost(post);
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
      include: {
        author: { select: { username: true, avatarSeed: true } },
        media: { orderBy: { sortOrder: 'asc' } },
      },
    });

    await this.updateHashtagStats(hashtags);
    return this.mapPost(updated);
  }

  async deletePost(authorId: string, postId: string) {
    const post = await this.prisma.post.findFirst({ where: { id: postId } });
    if (!post) throw new NotFoundException('Post not found');
    if (post.authorId !== authorId) throw new ForbiddenException();

    await this.prisma.post.update({
      where: { id: postId },
      data: { deletedAt: new Date() },
    });
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
        post: {
          include: {
            author: { select: { username: true, avatarSeed: true } },
            media: { orderBy: { sortOrder: 'asc' } },
          },
        },
      },
    });

    const hasMore = saves.length > take;
    const pageSaves = hasMore ? saves.slice(0, take) : saves;
    const savedIds = new Set(pageSaves.map((s) => s.postId));

    return {
      items: pageSaves.map((s) => this.mapPost(s.post, savedIds)),
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
      include: {
        author: { select: { username: true, avatarSeed: true } },
        media: { orderBy: { sortOrder: 'asc' } },
      },
    });

    const page = buildCursorPage(posts, take);
    return { ...page, items: page.items.map((p) => this.mapPost(p)) };
  }

  async postsByUser(username: string, cursor?: string, limit = 20, viewerId?: string) {
    const user = await this.prisma.user.findUnique({ where: { username } });
    if (!user) throw new NotFoundException('User not found');
    return this.myPosts(user.id, cursor, limit);
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
