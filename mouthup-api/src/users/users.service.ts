import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuthUser } from '../common/types/auth-user';

const USERNAME_PATTERN = /^[A-Za-z][A-Za-z0-9_]{2,19}$/;

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async getMe(userId: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        username: true,
        usernameLocked: true,
        emailVerified: true,
        onboardingDone: true,
        avatarSeed: true,
        pushEnabled: true,
        dailyReminder: true,
        createdAt: true,
      },
    });
    return user;
  }

  async assignUsername(userId: string, username: string) {
    if (!USERNAME_PATTERN.test(username)) {
      throw new BadRequestException(
        'Username must be 3–20 chars, start with a letter, letters/numbers/underscore only',
      );
    }

    const user = await this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
    if (user.usernameLocked && user.username) {
      throw new BadRequestException('Username is permanent and cannot be changed');
    }

    try {
      return await this.prisma.user.update({
        where: { id: userId },
        data: {
          username,
          usernameLocked: true,
          onboardingDone: true,
        },
        select: {
          id: true,
          username: true,
          usernameLocked: true,
          onboardingDone: true,
        },
      });
    } catch {
      throw new BadRequestException('Username already taken');
    }
  }

  async getPublicProfile(username: string, viewerId?: string) {
    const user = await this.prisma.user.findUnique({
      where: { username },
      select: {
        id: true,
        username: true,
        avatarSeed: true,
        createdAt: true,
        bannedAt: true,
      },
    });
    if (!user || user.bannedAt) throw new NotFoundException('User not found');

    if (viewerId) {
      const blocked = await this.prisma.block.findFirst({
        where: {
          OR: [
            { blockerId: viewerId, blockedId: user.id },
            { blockerId: user.id, blockedId: viewerId },
          ],
        },
      });
      if (blocked) throw new NotFoundException('User not found');
    }

    const postCount = await this.prisma.post.count({
      where: { authorId: user.id, deletedAt: null },
    });

    return { ...user, postCount };
  }

  async blockUser(blockerId: string, blockedUsername: string) {
    const blocked = await this.prisma.user.findUnique({
      where: { username: blockedUsername },
    });
    if (!blocked) throw new NotFoundException('User not found');
    if (blocked.id === blockerId) throw new BadRequestException('Cannot block yourself');

    await this.prisma.block.upsert({
      where: { blockerId_blockedId: { blockerId, blockedId: blocked.id } },
      create: { blockerId, blockedId: blocked.id },
      update: {},
    });
    return { message: 'User blocked' };
  }

  async unblockUser(blockerId: string, blockedUsername: string) {
    const blocked = await this.prisma.user.findUnique({
      where: { username: blockedUsername },
    });
    if (!blocked) throw new NotFoundException('User not found');

    await this.prisma.block.deleteMany({
      where: { blockerId, blockedId: blocked.id },
    });
    return { message: 'User unblocked' };
  }

  async listBlocked(blockerId: string) {
    const blocks = await this.prisma.block.findMany({
      where: { blockerId },
      include: {
        blocked: { select: { username: true, avatarSeed: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    return blocks.map((b) => ({
      nickname: b.blocked.username,
      avatarSeed: b.blocked.avatarSeed,
      blockedAt: b.createdAt,
    }));
  }

  async updatePreferences(
    userId: string,
    data: { pushEnabled?: boolean; dailyReminder?: boolean },
  ) {
    return this.prisma.user.update({
      where: { id: userId },
      data,
      select: { pushEnabled: true, dailyReminder: true },
    });
  }

  updateFcmToken(userId: string, token: string) {
    return this.prisma.user.update({
      where: { id: userId },
      data: { fcmToken: token },
      select: { pushEnabled: true },
    });
  }

  getBlockedIdsForUser(blockedByUserId: string) {
    return this.prisma.block.findMany({
      where: { blockerId: blockedByUserId },
      select: { blockedId: true },
    });
  }
}
