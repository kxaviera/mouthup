import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { NotificationType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ModerationService } from '../moderation/moderation.service';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class CommentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly moderation: ModerationService,
    private readonly notifications: NotificationsService,
  ) {}

  async list(postId: string) {
    return this.prisma.comment.findMany({
      where: { postId, deletedAt: null },
      orderBy: { createdAt: 'asc' },
      include: {
        author: { select: { username: true, avatarSeed: true } },
      },
    });
  }

  async add(postId: string, authorId: string, content: string) {
    const post = await this.prisma.post.findFirst({
      where: { id: postId, deletedAt: null },
      include: { author: { select: { id: true, username: true } } },
    });
    if (!post) throw new NotFoundException('Post not found');

    const mod = await this.moderation.check(content);
    if (!mod.allowed) throw new BadRequestException(mod.reason);

    const comment = await this.prisma.comment.create({
      data: { postId, authorId, content: content.trim() },
      include: {
        author: { select: { username: true, avatarSeed: true } },
      },
    });

    if (post.authorId !== authorId) {
      const author = comment.author.username ?? 'Someone';
      await this.notifications.create({
        userId: post.authorId,
        type: NotificationType.COMMENT,
        title: 'New comment',
        body: `${author} commented on your post`,
        route: `/post/${postId}`,
      });
    }

    return comment;
  }

  async remove(commentId: string, userId: string) {
    const comment = await this.prisma.comment.findUnique({
      where: { id: commentId },
    });
    if (!comment || comment.deletedAt) throw new NotFoundException();
    if (comment.authorId !== userId) throw new ForbiddenException();

    await this.prisma.comment.update({
      where: { id: commentId },
      data: { deletedAt: new Date() },
    });
    return { message: 'Comment deleted' };
  }
}
