import { PrismaClient, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { BOT_REGIONS } from '../src/bots/bot-regions';

const prisma = new PrismaClient();

async function seedBots() {
  if (process.env.SEED_BOTS === 'false') return;

  let created = 0;

  for (const region of BOT_REGIONS) {
    const email = `bot-${region.slug}@mouthup-bots.local`;
    const existing = await prisma.user.findUnique({ where: { email } });

    if (existing) {
      await prisma.user.update({
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
    } else {
      await prisma.user.create({
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

  console.log(`Bot accounts: ${BOT_REGIONS.length} regions (${created} new)`);
}

async function main() {
  const adminEmail = process.env.ADMIN_EMAIL ?? 'admin@mouthup.app';
  const adminPassword = process.env.ADMIN_PASSWORD;

  if (!adminPassword || adminPassword.length < 12) {
    if (process.env.NODE_ENV === 'production') {
      throw new Error('ADMIN_PASSWORD must be set (min 12 chars) before seeding in production');
    }
    console.warn('WARNING: Using dev-only admin password. Set ADMIN_PASSWORD before production deploy.');
  }

  const resolvedPassword = adminPassword ?? 'dev-only-change-me';
  const adminHash = await bcrypt.hash(resolvedPassword, 12);
  await prisma.user.upsert({
    where: { email: adminEmail },
    update: {},
    create: {
      email: adminEmail,
      passwordHash: adminHash,
      username: 'MouthUpAdmin',
      usernameLocked: true,
      emailVerified: true,
      onboardingDone: true,
      role: UserRole.SUPER_ADMIN,
    },
  });

  await seedBots();

  console.log('Seed complete');
  if (process.env.NODE_ENV !== 'production') {
    console.log(`Admin: ${adminEmail} / ${resolvedPassword}`);
  } else {
    console.log(`Admin account ready: ${adminEmail}`);
  }
  console.log(`${BOT_REGIONS.length} regional news bots configured`);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
