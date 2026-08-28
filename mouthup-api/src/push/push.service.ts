import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { FirebaseService } from '../firebase/firebase.service';

@Injectable()
export class PushService {
  private readonly logger = new Logger(PushService.name);

  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
    private readonly firebase: FirebaseService,
  ) {}

  isConfigured(): boolean {
    return this.firebase.isConfigured() || !!this.config.get('FCM_SERVER_KEY');
  }

  async sendToUser(
    userId: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true, pushEnabled: true },
    });
    if (!user?.fcmToken || !user.pushEnabled) return;

    if (this.firebase.isConfigured()) {
      const ok = await this.firebase.sendPush(user.fcmToken, title, body, data);
      if (ok) return;
    }

    const key = this.config.get('FCM_SERVER_KEY');
    if (!key) return;

    try {
      const res = await fetch('https://fcm.googleapis.com/fcm/send', {
        method: 'POST',
        headers: {
          Authorization: `key=${key}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          to: user.fcmToken,
          notification: { title, body },
          data: data ?? {},
          priority: 'high',
        }),
      });
      if (!res.ok) {
        this.logger.warn(`FCM legacy failed for ${userId}: ${await res.text()}`);
      }
    } catch (err) {
      this.logger.error(`FCM error: ${err instanceof Error ? err.message : err}`);
    }
  }
}
