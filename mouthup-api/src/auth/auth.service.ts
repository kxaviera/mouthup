import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { createHash, randomInt } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { AuthUser } from '../common/types/auth-user';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  hashPassword(password: string) {
    return bcrypt.hash(password, 12);
  }

  verifyPassword(password: string, hash: string) {
    return bcrypt.compare(password, hash);
  }

  toAuthUser(user: {
    id: string;
    email: string;
    username: string | null;
    role: AuthUser['role'];
    emailVerified: boolean;
    onboardingDone: boolean;
    bannedAt: Date | null;
  }): AuthUser {
    return {
      id: user.id,
      email: user.email,
      username: user.username,
      role: user.role,
      emailVerified: user.emailVerified,
      onboardingDone: user.onboardingDone,
      bannedAt: user.bannedAt,
    };
  }

  private hashToken(token: string) {
    return createHash('sha256').update(token).digest('hex');
  }

  async issueTokens(user: AuthUser) {
    const payload = { sub: user.id, email: user.email, role: user.role };
    const accessToken = await this.jwt.signAsync(payload, {
      secret: this.config.getOrThrow('JWT_ACCESS_SECRET'),
      expiresIn: this.config.get('JWT_ACCESS_EXPIRES', '15m'),
    });
    const refreshToken = await this.jwt.signAsync(payload, {
      secret: this.config.getOrThrow('JWT_REFRESH_SECRET'),
      expiresIn: this.config.get('JWT_REFRESH_EXPIRES', '30d'),
    });

    const refreshExpires = this.config.get('JWT_REFRESH_EXPIRES', '30d');
    const expiresAt = this.parseExpiry(refreshExpires);

    await this.prisma.refreshToken.create({
      data: {
        userId: user.id,
        tokenHash: this.hashToken(refreshToken),
        expiresAt,
      },
    });

    return { accessToken, refreshToken, user };
  }

  async refresh(refreshToken: string) {
    const payload = await this.jwt.verifyAsync<{ sub: string }>(refreshToken, {
      secret: this.config.getOrThrow('JWT_REFRESH_SECRET'),
    });

    const stored = await this.prisma.refreshToken.findUnique({
      where: { tokenHash: this.hashToken(refreshToken) },
    });
    if (!stored || stored.expiresAt < new Date()) {
      throw new Error('Invalid refresh token');
    }

    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: payload.sub },
    });
    if (user.bannedAt) throw new Error('Account suspended');

    await this.prisma.refreshToken.delete({ where: { id: stored.id } });
    return this.issueTokens(this.toAuthUser(user));
  }

  async logout(refreshToken: string) {
    await this.prisma.refreshToken.deleteMany({
      where: { tokenHash: this.hashToken(refreshToken) },
    });
  }

  generateCode() {
    return String(randomInt(100000, 999999));
  }

  async createVerificationCode(userId: string, purpose: string) {
    const code = this.generateCode();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);
    await this.prisma.verificationCode.create({
      data: { userId, code, purpose, expiresAt },
    });
    return code;
  }

  async consumeVerificationCode(userId: string, purpose: string, code: string) {
    const record = await this.prisma.verificationCode.findFirst({
      where: {
        userId,
        purpose,
        code,
        usedAt: null,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });
    if (!record) return false;
    await this.prisma.verificationCode.update({
      where: { id: record.id },
      data: { usedAt: new Date() },
    });
    return true;
  }

  private parseExpiry(value: string): Date {
    const match = /^(\d+)([smhd])$/.exec(value.trim());
    const now = Date.now();
    if (!match) return new Date(now + 30 * 24 * 60 * 60 * 1000);
    const n = Number(match[1]);
    const unit = match[2];
    const ms =
      unit === 's' ? n * 1000 :
      unit === 'm' ? n * 60 * 1000 :
      unit === 'h' ? n * 60 * 60 * 1000 :
      n * 24 * 60 * 60 * 1000;
    return new Date(now + ms);
  }
}
