import { PrismaClient, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function purgeLegacyBots() {
  const result = await prisma.user.deleteMany({ where: { isBot: true } });
  if (result.count > 0) {
    console.log(`Removed ${result.count} legacy bot accounts`);
  }
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
      username: 'ISZIAdmin',
      usernameLocked: true,
      emailVerified: true,
      onboardingDone: true,
      role: UserRole.SUPER_ADMIN,
    },
  });

  await purgeLegacyBots();

  console.log('Seed complete');
  if (process.env.NODE_ENV !== 'production') {
    console.log(`Admin: ${adminEmail} / ${resolvedPassword}`);
  } else {
    console.log(`Admin account ready: ${adminEmail}`);
  }
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
