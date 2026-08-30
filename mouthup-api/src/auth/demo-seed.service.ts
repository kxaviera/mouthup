import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AccountType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AuthService } from './auth.service';

export const DEMO_EMAIL = 'demo@mouthup.app';
export const DEMO_PASSWORD = 'demo123';
export const DEMO_USERNAME = 'CoolBreeze47';

@Injectable()
export class DemoSeedService implements OnModuleInit {
  private readonly logger = new Logger(DemoSeedService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly auth: AuthService,
    private readonly config: ConfigService,
  ) {}

  isEnabled() {
    return this.config.get('DEMO_LOGIN_ENABLED') !== 'false';
  }

  async onModuleInit() {
    if (!this.isEnabled()) return;
    try {
      await this.ensureDemoUser();
      this.logger.log(`Demo login ready (${DEMO_EMAIL})`);
    } catch (err) {
      this.logger.warn(`Demo user seed skipped: ${(err as Error).message}`);
    }
  }

  async ensureDemoUser() {
    const passwordHash = await this.auth.hashPassword(DEMO_PASSWORD);
    return this.prisma.user.upsert({
      where: { email: DEMO_EMAIL },
      update: {
        passwordHash,
        username: DEMO_USERNAME,
        screenName: 'Cool Breeze',
        usernameLocked: true,
        emailVerified: true,
        onboardingDone: true,
        accountType: AccountType.BOTH,
        city: 'Mumbai',
        isVerified: true,
        bannedAt: null,
      },
      create: {
        email: DEMO_EMAIL,
        passwordHash,
        username: DEMO_USERNAME,
        screenName: 'Cool Breeze',
        usernameLocked: true,
        emailVerified: true,
        onboardingDone: true,
        accountType: AccountType.BOTH,
        city: 'Mumbai',
        isVerified: true,
      },
    });
  }
}
