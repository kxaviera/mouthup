import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  applicationDefault,
  cert,
  getApps,
  initializeApp,
  type App,
  type ServiceAccount,
} from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getMessaging } from 'firebase-admin/messaging';

@Injectable()
export class FirebaseService implements OnModuleInit {
  private readonly logger = new Logger(FirebaseService.name);
  private app: App | null = null;
  private ready = false;

  constructor(private readonly config: ConfigService) {}

  onModuleInit() {
    if (getApps().length > 0) {
      this.app = getApps()[0]!;
      this.ready = true;
      return;
    }

    const json = this.config.get<string>('FIREBASE_SERVICE_ACCOUNT_JSON');
    const credPath = this.config.get<string>('GOOGLE_APPLICATION_CREDENTIALS');

    try {
      if (json) {
        const serviceAccount = JSON.parse(json) as ServiceAccount;
        this.app = initializeApp({
          credential: cert(serviceAccount),
        });
        this.ready = true;
        this.logger.log('Firebase Admin initialized from FIREBASE_SERVICE_ACCOUNT_JSON');
        return;
      }

      if (credPath) {
        this.app = initializeApp({
          credential: applicationDefault(),
        });
        this.ready = true;
        this.logger.log('Firebase Admin initialized from GOOGLE_APPLICATION_CREDENTIALS');
      }
    } catch (err) {
      this.logger.warn(
        `Firebase Admin not configured: ${err instanceof Error ? err.message : err}`,
      );
    }
  }

  isConfigured(): boolean {
    return this.ready;
  }

  async verifyIdToken(idToken: string) {
    if (!this.app) throw new Error('Firebase not configured');
    return getAuth(this.app).verifyIdToken(idToken);
  }

  async sendPush(
    token: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<boolean> {
    if (!this.app) return false;

    try {
      await getMessaging(this.app).send({
        token,
        notification: { title, body },
        data: data ?? {},
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default' } } },
      });
      return true;
    } catch (err) {
      this.logger.warn(`FCM v1 send failed: ${err instanceof Error ? err.message : err}`);
      return false;
    }
  }
}
