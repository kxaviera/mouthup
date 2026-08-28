import { Injectable, NotFoundException } from '@nestjs/common';
import { ReportStatus, ReportTargetType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ReportsService {
  constructor(private readonly prisma: PrismaService) {}

  async reportPost(reporterId: string, postId: string, reason: string) {
    const post = await this.prisma.post.findFirst({ where: { id: postId } });
    if (!post) throw new NotFoundException('Post not found');

    return this.prisma.report.create({
      data: {
        reporterId,
        targetType: ReportTargetType.POST,
        targetPostId: postId,
        reason,
      },
    });
  }

  async reportUser(reporterId: string, username: string, reason: string) {
    const user = await this.prisma.user.findUnique({ where: { username } });
    if (!user) throw new NotFoundException('User not found');

    return this.prisma.report.create({
      data: {
        reporterId,
        targetType: ReportTargetType.USER,
        targetUserId: user.id,
        reason,
      },
    });
  }

  async reportComment(reporterId: string, commentId: string, reason: string) {
    const comment = await this.prisma.comment.findFirst({
      where: { id: commentId, deletedAt: null },
    });
    if (!comment) throw new NotFoundException('Comment not found');

    return this.prisma.report.create({
      data: {
        reporterId,
        targetType: ReportTargetType.COMMENT,
        targetCommentId: commentId,
        reason,
      },
    });
  }

  async listPending(limit = 50) {
    const reports = await this.prisma.report.findMany({
      where: { status: ReportStatus.PENDING },
      take: limit,
      orderBy: { createdAt: 'desc' },
      include: {
        reporter: { select: { username: true, email: true } },
        targetPost: {
          select: { id: true, content: true, author: { select: { username: true } } },
        },
      },
    });

    return Promise.all(
      reports.map(async (r) => {
        let targetComment: { content: string; author: { username: string | null } } | null = null;
        let targetUser: { username: string | null; email: string } | null = null;

        if (r.targetCommentId) {
          const c = await this.prisma.comment.findUnique({
            where: { id: r.targetCommentId },
            select: { content: true, author: { select: { username: true } } },
          });
          if (c) targetComment = c;
        }
        if (r.targetUserId) {
          const u = await this.prisma.user.findUnique({
            where: { id: r.targetUserId },
            select: { username: true, email: true },
          });
          if (u) targetUser = u;
        }

        return { ...r, targetComment, targetUser };
      }),
    );
  }

  async resolve(
    reportId: string,
    status: ReportStatus,
    adminNote?: string,
  ) {
    return this.prisma.report.update({
      where: { id: reportId },
      data: {
        status,
        adminNote,
        resolvedAt: new Date(),
      },
    });
  }
}
