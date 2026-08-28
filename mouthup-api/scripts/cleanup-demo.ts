import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Removing demo data and fake bot posts…');

  const bots = await prisma.user.findMany({ where: { isBot: true }, select: { id: true } });
  const botIds = bots.map((b) => b.id);

  const demoUser = await prisma.user.findUnique({ where: { email: 'demo@mouthup.app' } });

  const authorIds = [...botIds];
  if (demoUser) authorIds.push(demoUser.id);

  if (authorIds.length > 0) {
    const deletedPosts = await prisma.post.deleteMany({
      where: { authorId: { in: authorIds } },
    });
    console.log(`Deleted ${deletedPosts.count} demo/fake posts`);
  }

  // Remove leftover fake media posts (picsum / sample videos)
  const fakeMedia = await prisma.post.findMany({
    where: {
      media: {
        some: {
          OR: [
            { url: { contains: 'picsum.photos' } },
            { url: { contains: 'gtv-videos-bucket' } },
          ],
        },
      },
    },
    select: { id: true },
  });
  if (fakeMedia.length > 0) {
    await prisma.post.deleteMany({ where: { id: { in: fakeMedia.map((p) => p.id) } } });
    console.log(`Deleted ${fakeMedia.length} posts with placeholder media`);
  }

  if (demoUser) {
    await prisma.user.delete({ where: { id: demoUser.id } });
    console.log('Removed demo user (demo@mouthup.app)');
  }

  await prisma.hashtagStat.deleteMany({});
  console.log('Reset hashtag stats');

  const remaining = await prisma.post.count({ where: { deletedAt: null } });
  console.log(`Cleanup done — ${remaining} posts remain in feed`);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
