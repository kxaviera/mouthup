import { Injectable } from '@nestjs/common';
import { NotificationType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { PushService } from '../push/push.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';

@Injectable()
export class NotificationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly push: PushService,
    private readonly realtime: RealtimeGateway,
  ) {}

  list(userId: string, limit = 50) {
    return this.prisma.notification.findMany({
      where: { userId },
      take: limit,
      orderBy: { createdAt: 'desc' },
    });
  }

  markRead(userId: string, id: string) {
    return this.prisma.notification.updateMany({
      where: { id, userId },
      data: { read: true },
    });
  }

  markAllRead(userId: string) {
    return this.prisma.notification.updateMany({
      where: { userId, read: false },
      data: { read: true },
    });
  }

  async create(params: {
    userId: string;
    type: NotificationType;
    title: string;
    body: string;
    route?: string;
  }) {
    const notification = await this.prisma.notification.create({ data: params });

    this.realtime.emitNotification(params.userId, {
      id: notification.id,
      type: notification.type,
      title: notification.title,
      body: notification.body,
      route: notification.route,
      createdAt: notification.createdAt,
    });

    await this.push.sendToUser(params.userId, params.title, params.body, {
      route: params.route ?? '',
      notificationId: notification.id,
    });

    return notification;
  }
}
