import { Controller, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { AdminGuard } from '../common/guards/admin.guard';
import { BotPostingService } from './bot-posting.service';

@Controller('admin/bots')
@UseGuards(JwtAuthGuard, AdminGuard)
export class BotsAdminController {
  constructor(private readonly botPosting: BotPostingService) {}

  /** Manually trigger one post cycle for all bots (admin only) */
  @Post('post-now')
  postNow() {
    return this.botPosting.postForAllBots('manual');
  }
}
