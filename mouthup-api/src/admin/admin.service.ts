import { Injectable } from '@nestjs/common';
import { ReportStatus, UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ReportsService } from '../reports/reports.service';

@Injectable()
export class AdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reports: ReportsService,
  ) {}

  async dashboard() {
    const [users, posts, pendingReports, messages] = await Promise.all([
      this.prisma.user.count({ where: { role: UserRole.USER } }),
      this.prisma.post.count({ where: { deletedAt: null } }),
      this.prisma.report.count({ where: { status: ReportStatus.PENDING } }),
      this.prisma.directMessage.count(),
    ]);

    return { users, posts, pendingReports, messages };
  }

  pendingReports(limit = 50) {
    return this.reports.listPending(limit);
  }

  resolveReport(reportId: string, status: ReportStatus, adminNote?: string) {
    return this.reports.resolve(reportId, status, adminNote);
  }

  async banUser(userId: string, reason: string) {
    return this.prisma.user.update({
      where: { id: userId },
      data: { bannedAt: new Date(), banReason: reason },
    });
  }

  async unbanUser(userId: string) {
    return this.prisma.user.update({
      where: { id: userId },
      data: { bannedAt: null, banReason: null },
    });
  }

  async deletePost(postId: string) {
    return this.prisma.post.update({
      where: { id: postId },
      data: { deletedAt: new Date() },
    });
  }

  searchUsers(q: string, limit = 20) {
    const trimmed = q.trim();
    return this.prisma.user.findMany({
      where: trimmed
        ? {
            OR: [
              { username: { contains: trimmed, mode: 'insensitive' } },
              { email: { contains: trimmed, mode: 'insensitive' } },
            ],
          }
        : { role: UserRole.USER, isBot: false },
      take: limit,
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        email: true,
        username: true,
        bannedAt: true,
        createdAt: true,
        signupIp: true,
        signupCountry: true,
        signupRegion: true,
        signupCity: true,
        authProvider: true,
      },
    });
  }

  searchPosts(q: string, limit = 20) {
    return this.prisma.post.findMany({
      where: {
        deletedAt: null,
        content: { contains: q, mode: 'insensitive' },
      },
      take: limit,
      orderBy: { createdAt: 'desc' },
      include: {
        author: { select: { username: true } },
      },
    });
  }
}
