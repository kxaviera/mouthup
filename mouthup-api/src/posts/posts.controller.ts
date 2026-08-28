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
import { IsArray, IsOptional, IsString, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { PostsService } from './posts.service';
import { JwtAuthGuard, OptionalJwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { VerifiedUserGuard } from '../common/guards/admin.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/types/auth-user';
import { CursorPaginationDto } from '../common/dto/cursor-pagination.dto';

class MediaItemDto {
  @IsString()
  type!: 'IMAGE' | 'VIDEO';

  @IsString()
  url!: string;
}

class CreatePostDto {
  @IsString()
  content!: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => MediaItemDto)
  media?: MediaItemDto[];
}

class UpdatePostDto {
  @IsString()
  content!: string;
}

class FeedQueryDto extends CursorPaginationDto {
  @IsOptional()
  @IsString()
  hashtag?: string;
}

@Controller('posts')
export class PostsController {
  constructor(private readonly posts: PostsService) {}

  @Get()
  @UseGuards(OptionalJwtAuthGuard)
  feed(@Query() query: FeedQueryDto, @CurrentUser() user?: AuthUser | null) {
    return this.posts.feed({
      cursor: query.cursor,
      limit: query.limit,
      hashtag: query.hashtag,
      viewerId: user?.id,
    });
  }

  @Get('trending-hashtags')
  trending() {
    return this.posts.trendingHashtags();
  }

  @Get('saved')
  @UseGuards(JwtAuthGuard)
  saved(@CurrentUser() user: AuthUser, @Query() query: CursorPaginationDto) {
    return this.posts.savedPosts(user.id, query.cursor, query.limit);
  }

  @Get('mine')
  @UseGuards(JwtAuthGuard, VerifiedUserGuard)
  mine(@CurrentUser() user: AuthUser, @Query() query: CursorPaginationDto) {
    return this.posts.myPosts(user.id, query.cursor, query.limit);
  }

  @Get(':id')
  @UseGuards(OptionalJwtAuthGuard)
  getOne(@Param('id') id: string, @CurrentUser() user?: AuthUser | null) {
    return this.posts.getById(id, user?.id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, VerifiedUserGuard)
  create(@CurrentUser() user: AuthUser, @Body() dto: CreatePostDto) {
    return this.posts.create(user.id, dto.content, dto.media ?? []);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, VerifiedUserGuard)
  update(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: UpdatePostDto,
  ) {
    return this.posts.updatePost(user.id, id, dto.content);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, VerifiedUserGuard)
  remove(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.posts.deletePost(user.id, id);
  }

  @Post(':id/save')
  @UseGuards(JwtAuthGuard)
  save(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.posts.toggleSave(user.id, id);
  }
}
