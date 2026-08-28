import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { MessageType, NotificationType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ModerationService } from '../moderation/moderation.service';
import { NotificationsService } from '../notifications/notifications.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';

@Injectable()
export class MessagesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly moderation: ModerationService,
    private readonly notifications: NotificationsService,
    private readonly realtime: RealtimeGateway,
  ) {}

  async conversations(userId: string) {
    const messages = await this.prisma.directMessage.findMany({
      where: {
        OR: [{ senderId: userId }, { recipientId: userId }],
      },
      orderBy: { createdAt: 'desc' },
      include: {
        sender: { select: { id: true, username: true, avatarSeed: true } },
        recipient: { select: { id: true, username: true, avatarSeed: true } },
      },
    });

    const seen = new Set<string>();
    const threads: {
      peer: string;
      peerAvatarSeed: string;
      lastMessage: string;
      lastAt: Date;
      unread: number;
    }[] = [];

    for (const m of messages) {
      const peerUser = m.senderId === userId ? m.recipient : m.sender;
      const peer = peerUser.username ?? peerUser.id;
      if (seen.has(peer)) continue;
      seen.add(peer);

      const unread = await this.prisma.directMessage.count({
        where: {
          senderId: peerUser.id,
          recipientId: userId,
          readAt: null,
        },
      });

      threads.push({
        peer,
        peerAvatarSeed: peerUser.avatarSeed,
        lastMessage: m.content,
        lastAt: m.createdAt,
        unread,
      });
    }

    return threads;
  }

  async thread(userId: string, peerUsername: string, limit = 50) {
    const peer = await this.prisma.user.findUnique({
      where: { username: peerUsername },
    });
    if (!peer) throw new NotFoundException('User not found');

    const messages = await this.prisma.directMessage.findMany({
      where: {
        OR: [
          { senderId: userId, recipientId: peer.id },
          { senderId: peer.id, recipientId: userId },
        ],
      },
      take: limit,
      orderBy: { createdAt: 'asc' },
      include: {
        sender: { select: { username: true } },
      },
    });

    await this.prisma.directMessage.updateMany({
      where: { senderId: peer.id, recipientId: userId, readAt: null },
      data: { readAt: new Date() },
    });

    return messages.map((m) => ({
      id: m.id,
      fromMe: m.senderId === userId,
      author: m.sender.username ?? 'Anonymous',
      type: m.type,
      content: m.content,
      createdAt: m.createdAt,
    }));
  }

  private async assertCanMessage(senderId: string, recipientId: string) {
    const block = await this.prisma.block.findFirst({
      where: {
        OR: [
          { blockerId: senderId, blockedId: recipientId },
          { blockerId: recipientId, blockedId: senderId },
        ],
      },
    });
    if (block) throw new ForbiddenException('Cannot message this user');
  }

  async send(
    senderId: string,
    peerUsername: string,
    content: string,
    type: MessageType = MessageType.TEXT,
  ) {
    const peer = await this.prisma.user.findUnique({
      where: { username: peerUsername },
    });
    if (!peer) throw new NotFoundException('User not found');

    await this.assertCanMessage(senderId, peer.id);

    if (type === MessageType.TEXT) {
      const mod = await this.moderation.check(content);
      if (!mod.allowed) throw new Error(mod.reason);
    }

    const message = await this.prisma.directMessage.create({
      data: {
        senderId,
        recipientId: peer.id,
        type,
        content,
      },
    });

    const sender = await this.prisma.user.findUnique({
      where: { id: senderId },
      select: { username: true },
    });

    const payload = {
      id: message.id,
      fromMe: false,
      author: sender?.username ?? 'Anonymous',
      type: message.type,
      content: message.content,
      createdAt: message.createdAt,
      peer: sender?.username ?? '',
    };

    this.realtime.emitNewDm(peer.id, payload);

    await this.notifications.create({
      userId: peer.id,
      type: NotificationType.DM,
      title: 'New message',
      body: `${sender?.username ?? 'Someone'} sent you a message`,
      route: `/messages/${sender?.username ?? ''}`,
    });

    return message;
  }
}
