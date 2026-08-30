import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { IsBoolean, IsIn, IsOptional, IsString, Matches, MaxLength, MinLength } from 'class-validator';
import { UsersService } from './users.service';
import { CompleteProfileDto } from './dto/complete-profile.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { VerifiedUserGuard } from '../common/guards/admin.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/types/auth-user';

class AssignUsernameDto {
  @IsString()
  @MinLength(3)
  @Matches(/^[A-Za-z][A-Za-z0-9_]{2,19}$/)
  username!: string;

  @IsString()
  @MinLength(2)
  @MaxLength(40)
  screenName!: string;
}

class ScreenNameDto {
  @IsString()
  @MinLength(2)
  @MaxLength(40)
  screenName!: string;
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
    return this.users.assignUsername(user.id, dto.username, dto.screenName);
  }

  @Patch('screen-name')
  updateScreenName(@CurrentUser() user: AuthUser, @Body() dto: ScreenNameDto) {
    return this.users.updateScreenName(user.id, dto.screenName);
  }

  @Post('onboarding/complete')
  @UseGuards(VerifiedUserGuard)
  completeProfile(@CurrentUser() user: AuthUser, @Body() dto: CompleteProfileDto) {
    return this.users.completeProfile(user.id, dto);
  }

  @Post(':username/follow')
  follow(@CurrentUser() user: AuthUser, @Param('username') username: string) {
    return this.users.followUser(user.id, username);
  }

  @Delete(':username/follow')
  unfollow(@CurrentUser() user: AuthUser, @Param('username') username: string) {
    return this.users.unfollowUser(user.id, username);
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

  @Get('me/followers')
  myFollowers(@CurrentUser() user: AuthUser) {
    return this.users.listFollowers(user.id);
  }

  @Get('me/following')
  myFollowing(@CurrentUser() user: AuthUser) {
    return this.users.listFollowing(user.id);
  }

  @Get('search')
  searchUsers(@Query('q') q: string) {
    return this.users.searchUsers(q ?? '');
  }

  @Get(':username')
  getProfile(@CurrentUser() user: AuthUser, @Param('username') username: string) {
    return this.users.getPublicProfile(username, user.id);
  }
}
