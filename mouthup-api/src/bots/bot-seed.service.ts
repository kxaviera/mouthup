import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { BOT_REGIONS } from './bot-regions';

@Injectable()
export class BotSeedService {
  private readonly logger = new Logger(BotSeedService.name);

  constructor(private readonly prisma: PrismaService) {}

  async seedBots() {
    let created = 0;
    let updated = 0;

    for (const region of BOT_REGIONS) {
      const email = `bot-${region.slug}@mouthup-bots.local`;
      const existing = await this.prisma.user.findUnique({ where: { email } });

      if (existing) {
        await this.prisma.user.update({
          where: { email },
          data: {
            isBot: true,
            passwordHash: null,
            region: region.name,
            username: region.username,
            emailVerified: true,
            onboardingDone: true,
            avatarSeed: region.slug,
          },
        });
        updated++;
      } else {
        await this.prisma.user.create({
          data: {
            email,
            passwordHash: null,
            username: region.username,
            usernameLocked: true,
            emailVerified: true,
            onboardingDone: true,
            isBot: true,
            region: region.name,
            avatarSeed: region.slug,
          },
        });
        created++;
      }
    }

    this.logger.log(`Bots seeded: ${created} created, ${updated} updated (${BOT_REGIONS.length} total)`);
    return { created, updated, total: BOT_REGIONS.length };
  }
}
