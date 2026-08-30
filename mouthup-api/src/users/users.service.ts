import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { AccountType, Profession } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CompleteProfileDto } from './dto/complete-profile.dto';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { geocodePlace } from '../common/utils/geo.util';

const USERNAME_PATTERN = /^[A-Za-z][A-Za-z0-9_]{2,19}$/;

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly realtime: RealtimeGateway,
  ) {}

  async getMe(userId: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        username: true,
        screenName: true,
        usernameLocked: true,
        emailVerified: true,
        onboardingDone: true,
        avatarSeed: true,
        pushEnabled: true,
        dailyReminder: true,
        accountType: true,
        profession: true,
        city: true,
        signupCity: true,
        createdAt: true,
        isVerified: true,
      },
    });
    const [followerCount, followingCount] = await Promise.all([
      this.prisma.follow.count({ where: { followingId: userId } }),
      this.prisma.follow.count({ where: { followerId: userId } }),
    ]);
    return { ...user, followerCount, followingCount };
  }

  async assignUsername(userId: string, username: string, screenName: string) {
    if (!USERNAME_PATTERN.test(username)) {
      throw new BadRequestException(
        'Username must be 3–20 chars, start with a letter, letters/numbers/underscore only',
      );
    }

    const trimmedScreen = screenName.trim();
    if (trimmedScreen.length < 2 || trimmedScreen.length > 40) {
      throw new BadRequestException('Screen name must be 2–40 characters');
    }

    const user = await this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
    if (user.usernameLocked && user.username) {
      throw new BadRequestException('Username is permanent and cannot be changed');
    }

    try {
      const updated = await this.prisma.user.update({
        where: { id: userId },
        data: {
          username,
          screenName: trimmedScreen,
          usernameLocked: true,
        },
        select: {
          id: true,
          email: true,
          username: true,
          screenName: true,
          usernameLocked: true,
          onboardingDone: true,
          accountType: true,
          profession: true,
          city: true,
          emailVerified: true,
          isVerified: true,
        },
      });
      const [followerCount, followingCount] = await Promise.all([
        this.prisma.follow.count({ where: { followingId: userId } }),
        this.prisma.follow.count({ where: { followerId: userId } }),
      ]);
      this.realtime.emitProfileUpdated(userId, {
        username: updated.username,
        screenName: updated.screenName,
      });
      return { ...updated, followerCount, followingCount };
    } catch {
      throw new BadRequestException('Username already taken');
    }
  }

  async updateScreenName(userId: string, screenName: string) {
    const trimmed = screenName.trim();
    if (trimmed.length < 2 || trimmed.length > 40) {
      throw new BadRequestException('Screen name must be 2–40 characters');
    }

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: { screenName: trimmed },
      select: {
        id: true,
        email: true,
        username: true,
        screenName: true,
        usernameLocked: true,
        onboardingDone: true,
        accountType: true,
        profession: true,
        city: true,
        emailVerified: true,
        isVerified: true,
      },
    });

    this.realtime.emitProfileUpdated(userId, {
      username: updated.username,
      screenName: updated.screenName,
    });

    const [followerCount, followingCount] = await Promise.all([
      this.prisma.follow.count({ where: { followingId: userId } }),
      this.prisma.follow.count({ where: { followerId: userId } }),
    ]);
    return { ...updated, followerCount, followingCount };
  }

  async completeProfile(userId: string, dto: CompleteProfileDto) {
    const user = await this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
    if (!user.username) {
      throw new BadRequestException('Choose a username first');
    }

    const accountType = dto.accountType as AccountType;
    let profession: Profession | undefined;
    if (dto.profession) {
      profession = dto.profession as Profession;
    }

    if (accountType === 'SERVICE_PROVIDER' && !profession) {
      throw new BadRequestException('Service providers must select a profession');
    }

    if (accountType !== 'SERVICE_PROVIDER') {
      profession = undefined;
    }

    const city = dto.city?.trim() || user.signupCity || user.city || undefined;
    const coords = geocodePlace(city);

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: {
        accountType,
        profession,
        city,
        latitude: coords?.lat ?? null,
        longitude: coords?.lng ?? null,
        onboardingDone: true,
      },
      select: {
        id: true,
        username: true,
        usernameLocked: true,
        onboardingDone: true,
        accountType: true,
        profession: true,
        city: true,
        isVerified: true,
      },
    });

    this.realtime.emitProfileUpdated(userId, {
      username: updated.username,
      accountType: updated.accountType,
      profession: updated.profession,
      city: updated.city,
      onboardingDone: updated.onboardingDone,
      isVerified: updated.isVerified,
    });

    return updated;
  }

  async getPublicProfile(username: string, viewerId?: string) {
    const user = await this.prisma.user.findUnique({
      where: { username },
      select: {
        id: true,
        username: true,
        screenName: true,
        avatarSeed: true,
        accountType: true,
        profession: true,
        city: true,
        createdAt: true,
        bannedAt: true,
        isVerified: true,
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

    const [postCount, followerCount, followingCount, isFollowing] = await Promise.all([
      this.prisma.post.count({ where: { authorId: user.id, deletedAt: null } }),
      this.prisma.follow.count({ where: { followingId: user.id } }),
      this.prisma.follow.count({ where: { followerId: user.id } }),
      viewerId
        ? this.prisma.follow
            .findUnique({
              where: {
                followerId_followingId: { followerId: viewerId, followingId: user.id },
              },
            })
            .then((f) => !!f)
        : Promise.resolve(false),
    ]);

    return { ...user, postCount, followerCount, followingCount, isFollowing };
  }

  async followUser(followerId: string, username: string) {
    const target = await this.prisma.user.findUnique({ where: { username } });
    if (!target) throw new NotFoundException('User not found');
    if (target.id === followerId) throw new BadRequestException('Cannot follow yourself');

    const follower = await this.prisma.user.findUniqueOrThrow({
      where: { id: followerId },
      select: { username: true },
    });

    await this.prisma.follow.upsert({
      where: {
        followerId_followingId: { followerId, followingId: target.id },
      },
      create: { followerId, followingId: target.id },
      update: {},
    });

    this.realtime.emitFollowNew(target.id, {
      followerUsername: follower.username,
      following: true,
    });

    return { following: true };
  }

  async unfollowUser(followerId: string, username: string) {
    const target = await this.prisma.user.findUnique({ where: { username } });
    if (!target) throw new NotFoundException('User not found');

    await this.prisma.follow.deleteMany({
      where: { followerId, followingId: target.id },
    });
    return { following: false };
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

  async searchUsers(q: string, limit = 20) {
    const take = Math.min(limit, 30);
    const users = await this.prisma.user.findMany({
      where: {
        bannedAt: null,
        username: { not: null },
        OR: [
          { username: { contains: q, mode: 'insensitive' } },
          { screenName: { contains: q, mode: 'insensitive' } },
          { profession: { equals: q.toUpperCase() as Profession } },
          { city: { contains: q, mode: 'insensitive' } },
        ],
      },
      take,
      select: {
        username: true,
        screenName: true,
        avatarSeed: true,
        accountType: true,
        profession: true,
        city: true,
        isVerified: true,
      },
      orderBy: { createdAt: 'desc' },
    });
    return users;
  }

  async listFollowing(userId: string) {
    const rows = await this.prisma.follow.findMany({
      where: { followerId: userId },
      include: { following: { select: { username: true } } },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((r) => r.following.username).filter(Boolean) as string[];
  }

  async listFollowers(userId: string) {
    const rows = await this.prisma.follow.findMany({
      where: { followingId: userId },
      include: { follower: { select: { username: true } } },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((r) => r.follower.username).filter(Boolean) as string[];
  }
}
