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
import { PostsService } from './posts.service';
import { CreateListingDto, ListingStatusDto } from './dto/create-listing.dto';
import { FeedQueryDto } from './dto/feed-query.dto';
import { JwtAuthGuard, OptionalJwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { VerifiedUserGuard } from '../common/guards/admin.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/types/auth-user';
import { CursorPaginationDto } from '../common/dto/cursor-pagination.dto';
import { SupportReactionDto } from './dto/support-reaction.dto';
import { UpdatePostDto } from './dto/update-post.dto';

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
      q: query.q,
      listingType: query.listingType,
      city: query.city,
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
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateListingDto) {
    return this.posts.createListing(user.id, dto);
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

  @Patch(':id/listing-status')
  @UseGuards(JwtAuthGuard, VerifiedUserGuard)
  listingStatus(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: ListingStatusDto,
  ) {
    return this.posts.updateListingStatus(user.id, id, dto.status);
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

  @Post(':id/like')
  @UseGuards(JwtAuthGuard)
  like(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.posts.toggleLike(user.id, id);
  }

  @Post(':id/support')
  @UseGuards(JwtAuthGuard)
  support(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: SupportReactionDto,
  ) {
    return this.posts.toggleSupportReaction(user.id, id, dto.type);
  }
}
