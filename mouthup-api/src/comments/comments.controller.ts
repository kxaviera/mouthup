import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { IsString } from 'class-validator';
import { CommentsService } from './comments.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { VerifiedUserGuard } from '../common/guards/admin.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/types/auth-user';

class AddCommentDto {
  @IsString()
  content!: string;
}

@Controller('posts/:postId/comments')
export class CommentsController {
  constructor(private readonly comments: CommentsService) {}

  @Get()
  list(@Param('postId') postId: string) {
    return this.comments.list(postId);
  }

  @Post()
  @UseGuards(JwtAuthGuard, VerifiedUserGuard)
  add(
    @Param('postId') postId: string,
    @CurrentUser() user: AuthUser,
    @Body() dto: AddCommentDto,
  ) {
    return this.comments.add(postId, user.id, dto.content);
  }

  @Delete(':commentId')
  @UseGuards(JwtAuthGuard)
  remove(
    @Param('commentId') commentId: string,
    @CurrentUser() user: AuthUser,
  ) {
    return this.comments.remove(commentId, user.id);
  }
}
