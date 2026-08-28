import { Module } from '@nestjs/common';
import { PostsModule } from '../posts/posts.module';
import { BotPostingService } from './bot-posting.service';
import { BotSeedService } from './bot-seed.service';
import { NewsFetcherService } from './news-fetcher.service';
import { BotsAdminController } from './bots-admin.controller';

@Module({
  imports: [PostsModule],
  controllers: [BotsAdminController],
  providers: [BotPostingService, BotSeedService, NewsFetcherService],
  exports: [BotPostingService, BotSeedService],
})
export class BotsModule {}
