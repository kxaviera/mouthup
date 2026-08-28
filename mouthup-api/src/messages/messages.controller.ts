import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { IsEnum, IsString } from 'class-validator';
import { MessageType } from '@prisma/client';
import { MessagesService } from './messages.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { VerifiedUserGuard } from '../common/guards/admin.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/types/auth-user';

class SendMessageDto {
  @IsString()
  content!: string;

  @IsEnum(MessageType)
  type: MessageType = MessageType.TEXT;
}

@Controller('messages')
@UseGuards(JwtAuthGuard, VerifiedUserGuard)
export class MessagesController {
  constructor(private readonly messages: MessagesService) {}

  @Get('conversations')
  conversations(@CurrentUser() user: AuthUser) {
    return this.messages.conversations(user.id);
  }

  @Get(':peer')
  thread(@CurrentUser() user: AuthUser, @Param('peer') peer: string) {
    return this.messages.thread(user.id, peer);
  }

  @Post(':peer')
  send(
    @CurrentUser() user: AuthUser,
    @Param('peer') peer: string,
    @Body() dto: SendMessageDto,
  ) {
    return this.messages.send(user.id, peer, dto.content, dto.type);
  }
}
