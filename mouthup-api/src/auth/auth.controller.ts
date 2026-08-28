import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  HttpCode,
  Post,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { AuthService } from './auth.service';
import { EmailService } from '../email/email.service';
import { FirebaseService } from '../firebase/firebase.service';
import {
  ForgotPasswordDto,
  FirebaseLoginDto,
  LoginDto,
  RefreshTokenDto,
  RegisterDto,
  ResetPasswordDto,
  VerifyEmailDto,
} from './dto/auth.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/types/auth-user';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auth: AuthService,
    private readonly email: EmailService,
    private readonly firebase: FirebaseService,
    private readonly config: ConfigService,
  ) {}

  private shouldAutoVerify(): boolean {
    if (this.config.get('AUTO_VERIFY_EMAIL') === 'true') return true;
    if (this.config.get('AUTO_VERIFY_EMAIL') === 'false') return false;
    return !this.email.isConfigured();
  }

  private devCode(code: string) {
    return this.config.get('NODE_ENV') !== 'production' ? { devCode: code } : {};
  }

  @Post('register')
  async register(@Body() dto: RegisterDto) {
    const existing = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase() },
    });
    if (existing) throw new BadRequestException('Email already registered');

    const autoVerify = this.shouldAutoVerify();
    const user = await this.prisma.user.create({
      data: {
        email: dto.email.toLowerCase(),
        passwordHash: await this.auth.hashPassword(dto.password),
        emailVerified: autoVerify,
      },
    });

    if (autoVerify) {
      return { message: 'Account created. You can sign in now.' };
    }

    const code = await this.auth.createVerificationCode(user.id, 'email_verify');
    await this.email.sendVerificationCode(user.email, code, 'verify');
    return { message: 'Account created. Check your email for the verification code.', ...this.devCode(code) };
  }

  @Post('verify-email')
  @UseGuards(JwtAuthGuard)
  async verifyEmail(@CurrentUser() user: AuthUser, @Body() dto: VerifyEmailDto) {
    const ok = await this.auth.consumeVerificationCode(
      user.id,
      'email_verify',
      dto.code,
    );
    if (!ok) throw new BadRequestException('Invalid or expired code');

    const updated = await this.prisma.user.update({
      where: { id: user.id },
      data: { emailVerified: true },
    });
    return { user: this.auth.toAuthUser(updated) };
  }

  @Post('resend-verification')
  @UseGuards(JwtAuthGuard)
  async resendVerification(@CurrentUser() user: AuthUser) {
    if (user.emailVerified) {
      throw new BadRequestException('Email already verified');
    }
    const code = await this.auth.createVerificationCode(user.id, 'email_verify');
    await this.email.sendVerificationCode(user.email, code, 'verify');
    return { message: 'Verification code sent', ...this.devCode(code) };
  }

  @Post('login')
  @HttpCode(200)
  async login(@Body() dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase() },
    });
    if (!user || !user.passwordHash) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const valid = await this.auth.verifyPassword(dto.password, user.passwordHash);
    if (!valid) throw new UnauthorizedException('Invalid credentials');
    if (user.bannedAt) throw new UnauthorizedException('Account suspended');

    return this.auth.issueTokens(this.auth.toAuthUser(user));
  }

  @Post('firebase')
  @HttpCode(200)
  async firebaseLogin(@Body() dto: FirebaseLoginDto) {
    if (!this.firebase.isConfigured()) {
      throw new BadRequestException('Firebase auth is not configured on the server');
    }

    let decoded: Awaited<ReturnType<FirebaseService['verifyIdToken']>>;
    try {
      decoded = await this.firebase.verifyIdToken(dto.idToken);
    } catch {
      throw new UnauthorizedException('Invalid Firebase token');
    }

    const uid = decoded.uid;
    const email = decoded.email?.toLowerCase();
    if (!email) {
      throw new BadRequestException('Firebase account must have an email address');
    }

    const provider = decoded.firebase?.sign_in_provider ?? 'firebase';

    let user = await this.prisma.user.findFirst({
      where: { OR: [{ firebaseUid: uid }, { email }] },
    });

    if (user?.bannedAt) throw new UnauthorizedException('Account suspended');

    if (user) {
      if (!user.firebaseUid || user.authProvider !== provider) {
        user = await this.prisma.user.update({
          where: { id: user.id },
          data: {
            firebaseUid: uid,
            authProvider: provider,
            emailVerified: true,
          },
        });
      }
    } else {
      user = await this.prisma.user.create({
        data: {
          email,
          firebaseUid: uid,
          authProvider: provider,
          emailVerified: true,
        },
      });
    }

    return this.auth.issueTokens(this.auth.toAuthUser(user));
  }

  @Post('refresh')
  @HttpCode(200)
  async refresh(@Body() dto: RefreshTokenDto) {
    try {
      return await this.auth.refresh(dto.refreshToken);
    } catch {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  @Post('logout')
  @HttpCode(200)
  async logout(@Body() dto: RefreshTokenDto) {
    await this.auth.logout(dto.refreshToken);
    return { message: 'Logged out' };
  }

  @Post('forgot-password')
  @HttpCode(200)
  async forgotPassword(@Body() dto: ForgotPasswordDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase() },
    });
    if (user) {
      const code = await this.auth.createVerificationCode(user.id, 'password_reset');
      await this.email.sendVerificationCode(user.email, code, 'reset');
      return { message: 'If the email exists, a reset code was sent', ...this.devCode(code) };
    }
    return { message: 'If the email exists, a reset code was sent' };
  }

  @Post('reset-password')
  @HttpCode(200)
  async resetPassword(@Body() dto: ResetPasswordDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase() },
    });
    if (!user) throw new BadRequestException('Invalid reset request');
    if (!user.passwordHash) {
      throw new BadRequestException('This account uses Google sign-in');
    }

    const ok = await this.auth.consumeVerificationCode(
      user.id,
      'password_reset',
      dto.code,
    );
    if (!ok) throw new BadRequestException('Invalid or expired code');

    await this.prisma.user.update({
      where: { id: user.id },
      data: { passwordHash: await this.auth.hashPassword(dto.newPassword) },
    });
    await this.prisma.refreshToken.deleteMany({ where: { userId: user.id } });
    return { message: 'Password updated' };
  }

  @Delete('account')
  @UseGuards(JwtAuthGuard)
  async deleteAccount(@CurrentUser() user: AuthUser) {
    await this.prisma.user.delete({ where: { id: user.id } });
    return { message: 'Account deleted' };
  }
}
