import { Injectable, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UserRole } from '@prisma/client';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
@WebSocketGateway({
  namespace: '/realtime',
  cors: {
    origin: (() => {
      const origins = [process.env.APP_URL, process.env.ADMIN_URL].filter(Boolean) as string[];
      if (process.env.NODE_ENV !== 'production') {
        origins.push(
          'http://localhost:57400',
          'http://localhost:57401',
          'http://localhost:57402',
          'http://127.0.0.1:57400',
          'http://127.0.0.1:57401',
          'http://127.0.0.1:57402',
          'http://localhost:3001',
          'http://127.0.0.1:3001',
        );
      }
      return origins.length > 0 ? origins : true;
    })(),
    credentials: true,
  },
})
export class RealtimeGateway implements OnGatewayConnection, OnGatewayDisconnect {
  private readonly logger = new Logger(RealtimeGateway.name);
  private readonly userSockets = new Map<string, Set<string>>();

  @WebSocketServer()
  server!: Server;

  constructor(
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  async handleConnection(client: Socket) {
    try {
      const token =
        (client.handshake.auth?.token as string | undefined) ??
        (client.handshake.query?.token as string | undefined);
      if (!token) throw new Error('No token');

      const payload = await this.jwt.verifyAsync<{ sub: string }>(token, {
        secret: this.config.getOrThrow('JWT_ACCESS_SECRET'),
      });

      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
        select: { id: true, bannedAt: true, city: true, role: true },
      });
      if (!user || user.bannedAt) throw new Error('Invalid user');

      client.data.userId = user.id;
      client.data.city = user.city ?? undefined;

      const set = this.userSockets.get(user.id) ?? new Set<string>();
      set.add(client.id);
      this.userSockets.set(user.id, set);

      client.join(`user:${user.id}`);
      client.join('marketplace');
      if (user.city) client.join(`city:${user.city}`);
      if (user.role === UserRole.ADMIN || user.role === UserRole.SUPER_ADMIN) {
        client.join('admin');
      }

      this.logger.debug(`Socket connected: ${user.id}`);
    } catch {
      client.disconnect(true);
    }
  }

  handleDisconnect(client: Socket) {
    const userId = client.data.userId as string | undefined;
    if (!userId) return;
    const set = this.userSockets.get(userId);
    if (!set) return;
    set.delete(client.id);
    if (set.size === 0) this.userSockets.delete(userId);
  }

  @SubscribeMessage('ping')
  handlePing(@ConnectedSocket() client: Socket) {
    client.emit('pong', { ts: Date.now() });
  }

  /** Switch city feed room after profile update */
  @SubscribeMessage('city:join')
  handleCityJoin(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { city?: string | null },
  ) {
    const prev = client.data.city as string | undefined;
    if (prev) client.leave(`city:${prev}`);
    const city = data?.city?.trim();
    if (city) {
      client.join(`city:${city}`);
      client.data.city = city;
    } else {
      client.data.city = undefined;
    }
  }

  /** Client joins a DM thread room for typing indicators (optional) */
  @SubscribeMessage('dm:join')
  handleDmJoin(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { peer: string },
  ) {
    const userId = client.data.userId as string | undefined;
    if (!userId || !data?.peer) return;
    client.join(`dm:${userId}:${data.peer}`);
  }

  emitToUser(userId: string, event: string, payload: unknown) {
    this.server.to(`user:${userId}`).emit(event, payload);
  }

  emitNewDm(recipientId: string, message: Record<string, unknown>) {
    this.emitToUser(recipientId, 'dm:new', message);
  }

  emitNotification(userId: string, notification: Record<string, unknown>) {
    this.emitToUser(userId, 'notification:new', notification);
  }

  emitNewFeedPost(post: Record<string, unknown>, city?: string | null) {
    if (city) this.server.to(`city:${city}`).emit('feed:new', post);
    this.server.to('marketplace').emit('feed:new', post);
    this.server.to('admin').emit('admin:refresh', { reason: 'feed:new' });
  }

  emitFeedUpdated(post: Record<string, unknown>, city?: string | null) {
    if (city) this.server.to(`city:${city}`).emit('feed:updated', post);
    this.server.to('marketplace').emit('feed:updated', post);
  }

  emitFeedRemoved(postId: string, city?: string | null) {
    if (city) this.server.to(`city:${city}`).emit('feed:removed', { id: postId });
    this.server.to('marketplace').emit('feed:removed', { id: postId });
    this.server.to('admin').emit('admin:refresh', { reason: 'feed:removed' });
  }

  emitProfileUpdated(userId: string, profile: Record<string, unknown>) {
    this.emitToUser(userId, 'profile:updated', profile);
  }

  emitFollowNew(userId: string, payload: Record<string, unknown>) {
    this.emitToUser(userId, 'follow:new', payload);
  }

  emitAdminStats(stats: Record<string, unknown>) {
    this.server.to('admin').emit('admin:stats', stats);
  }
}
