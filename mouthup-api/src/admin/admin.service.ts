import { Injectable } from '@nestjs/common';

import { ReportStatus, UserRole } from '@prisma/client';

import { PrismaService } from '../prisma/prisma.service';

import { ReportsService } from '../reports/reports.service';

import { RealtimeGateway } from '../realtime/realtime.gateway';



@Injectable()

export class AdminService {

  constructor(

    private readonly prisma: PrismaService,

    private readonly reports: ReportsService,

    private readonly realtime: RealtimeGateway,

  ) {}



  async dashboard() {

    const [users, posts, pendingReports, messages, verifiedUsers] = await Promise.all([

      this.prisma.user.count({ where: { role: UserRole.USER } }),

      this.prisma.post.count({ where: { deletedAt: null } }),

      this.prisma.report.count({ where: { status: ReportStatus.PENDING } }),

      this.prisma.directMessage.count(),

      this.prisma.user.count({ where: { role: UserRole.USER, isVerified: true } }),

    ]);



    return { users, posts, pendingReports, messages, verifiedUsers };

  }



  async broadcastDashboardStats() {

    const stats = await this.dashboard();

    this.realtime.emitAdminStats(stats);

    return stats;

  }



  pendingReports(limit = 50) {

    return this.reports.listPending(limit);

  }



  async resolveReport(reportId: string, status: ReportStatus, adminNote?: string) {

    const result = await this.reports.resolve(reportId, status, adminNote);

    await this.broadcastDashboardStats();

    return result;

  }



  async banUser(userId: string, reason: string) {

    const user = await this.prisma.user.update({

      where: { id: userId },

      data: { bannedAt: new Date(), banReason: reason },

    });

    this.realtime.emitProfileUpdated(userId, { banned: true, banReason: reason });

    await this.broadcastDashboardStats();

    return user;

  }



  async unbanUser(userId: string) {

    const user = await this.prisma.user.update({

      where: { id: userId },

      data: { bannedAt: null, banReason: null },

    });

    this.realtime.emitProfileUpdated(userId, { banned: false });

    await this.broadcastDashboardStats();

    return user;

  }



  async deletePost(postId: string) {
    const existing = await this.prisma.post.findUnique({
      where: { id: postId },
      select: { location: true, author: { select: { city: true } } },
    });

    const post = await this.prisma.post.update({
      where: { id: postId },
      data: { deletedAt: new Date() },
    });

    const city = existing?.location ?? existing?.author.city ?? null;
    this.realtime.emitFeedRemoved(postId, city);

    await this.broadcastDashboardStats();

    return post;

  }



  searchUsers(q: string, limit = 20) {

    const trimmed = q.trim();

    return this.prisma.user.findMany({

      where: trimmed

        ? {

            OR: [

              { username: { contains: trimmed, mode: 'insensitive' } },

              { screenName: { contains: trimmed, mode: 'insensitive' } },

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

        screenName: true,

        bannedAt: true,

        banReason: true,

        createdAt: true,

        signupIp: true,

        signupCountry: true,

        signupRegion: true,

        signupCity: true,

        authProvider: true,

        isVerified: true,

      },

    });

  }



  async verifyUser(userId: string) {

    const user = await this.prisma.user.update({

      where: { id: userId },

      data: { isVerified: true },

      select: { id: true, username: true, isVerified: true },

    });

    this.realtime.emitProfileUpdated(userId, {

      username: user.username,

      isVerified: true,

    });

    await this.broadcastDashboardStats();

    return user;

  }



  async unverifyUser(userId: string) {

    const user = await this.prisma.user.update({

      where: { id: userId },

      data: { isVerified: false },

      select: { id: true, username: true, isVerified: true },

    });

    this.realtime.emitProfileUpdated(userId, {

      username: user.username,

      isVerified: false,

    });

    await this.broadcastDashboardStats();

    return user;

  }



  searchPosts(q: string, limit = 100) {

    const trimmed = q.trim();

    return this.prisma.post.findMany({

      where: trimmed

        ? {

            deletedAt: null,

            content: { contains: trimmed, mode: 'insensitive' },

          }

        : { deletedAt: null },

      take: limit,

      orderBy: { createdAt: 'desc' },

      include: {

        author: { select: { username: true, email: true, isBot: true } },

        media: { select: { type: true, url: true }, orderBy: { sortOrder: 'asc' }, take: 3 },

      },

    });

  }

}

