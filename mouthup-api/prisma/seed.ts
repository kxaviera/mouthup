import { PrismaClient, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { BOT_REGIONS } from '../src/bots/bot-regions';

const prisma = new PrismaClient();
const BOT_PASSWORD = 'bot-internal-no-login';

async function seedBots() {
  if (process.env.SEED_BOTS === 'false') return;

  const passwordHash = await bcrypt.hash(BOT_PASSWORD, 10);
  let created = 0;

  for (const region of BOT_REGIONS) {
    const email = `bot-${region.slug}@mouthup-bots.local`;
    const existing = await prisma.user.findUnique({ where: { email } });

    if (existing) {
      await prisma.user.update({
        where: { email },
        data: {
          isBot: true,
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
          passwordHash,
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

async function seedDemoUser() {
  if (process.env.SEED_DEMO_USER === 'false') return;

  const passwordHash = await bcrypt.hash('demo123', 12);
  await prisma.user.upsert({
    where: { email: 'demo@mouthup.app' },
    update: {
      passwordHash,
      username: 'CoolBreeze47',
      screenName: 'Cool Breeze',
      usernameLocked: true,
      emailVerified: true,
      onboardingDone: true,
      accountType: 'BOTH',
      city: 'Mumbai',
      isVerified: true,
    },
    create: {
      email: 'demo@mouthup.app',
      passwordHash,
      username: 'CoolBreeze47',
      screenName: 'Cool Breeze',
      usernameLocked: true,
      emailVerified: true,
      onboardingDone: true,
      accountType: 'BOTH',
      city: 'Mumbai',
      isVerified: true,
    },
  });
  console.log('Demo user: demo@mouthup.app / demo123');
}

async function main() {
  const adminEmail = process.env.ADMIN_EMAIL ?? 'admin@mouthup.app';
  const adminPassword = process.env.ADMIN_PASSWORD ?? 'admin123change';

  const adminHash = await bcrypt.hash(adminPassword, 12);
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
  await seedDemoUser();

  console.log('Seed complete');
  if (process.env.NODE_ENV !== 'production') {
    console.log(`Admin: ${adminEmail} / ${adminPassword}`);
  } else {
    console.log(`Admin account ready: ${adminEmail}`);
  }
  console.log(`${BOT_REGIONS.length} regional news bots configured`);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
