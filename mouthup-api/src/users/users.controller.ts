import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { IsBoolean, IsOptional, IsString, Matches, MinLength } from 'class-validator';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { VerifiedUserGuard } from '../common/guards/admin.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/types/auth-user';

class AssignUsernameDto {
  @IsString()
  @MinLength(3)
  @Matches(/^[A-Za-z][A-Za-z0-9_]{2,19}$/)
  username!: string;
}

class PreferencesDto {
  @IsOptional()
  @IsBoolean()
  pushEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  dailyReminder?: boolean;
}

class FcmTokenDto {
  @IsString()
  token!: string;
}

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get('me')
  getMe(@CurrentUser() user: AuthUser) {
    return this.users.getMe(user.id);
  }

  @Post('username')
  @UseGuards(VerifiedUserGuard)
  assignUsername(@CurrentUser() user: AuthUser, @Body() dto: AssignUsernameDto) {
    return this.users.assignUsername(user.id, dto.username);
  }

  @Get('blocked')
  listBlocked(@CurrentUser() user: AuthUser) {
    return this.users.listBlocked(user.id);
  }

  @Post(':username/block')
  block(@CurrentUser() user: AuthUser, @Param('username') username: string) {
    return this.users.blockUser(user.id, username);
  }

  @Delete(':username/block')
  unblock(@CurrentUser() user: AuthUser, @Param('username') username: string) {
    return this.users.unblockUser(user.id, username);
  }

  @Patch('preferences')
  updatePreferences(@CurrentUser() user: AuthUser, @Body() dto: PreferencesDto) {
    return this.users.updatePreferences(user.id, dto);
  }

  @Patch('fcm-token')
  updateFcmToken(@CurrentUser() user: AuthUser, @Body() dto: FcmTokenDto) {
    return this.users.updateFcmToken(user.id, dto.token);
  }

  @Get(':username')
  getProfile(@CurrentUser() user: AuthUser, @Param('username') username: string) {
    return this.users.getPublicProfile(username, user.id);
  }
}
