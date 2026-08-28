import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import { PrismaModule } from './prisma/prisma.module';
import { EmailModule } from './email/email.module';
import { StorageModule } from './storage/storage.module';
import { PushModule } from './push/push.module';
import { FirebaseModule } from './firebase/firebase.module';
import { RealtimeModule } from './realtime/realtime.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { PostsModule } from './posts/posts.module';
import { CommentsModule } from './comments/comments.module';
import { MessagesModule } from './messages/messages.module';
import { NotificationsModule } from './notifications/notifications.module';
import { ReportsModule } from './reports/reports.module';
import { AdminModule } from './admin/admin.module';
import { ModerationModule } from './moderation/moderation.module';
import { BotsModule } from './bots/bots.module';
import { MediaModule } from './media/media.module';
import { HealthController } from './health.controller';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ScheduleModule.forRoot(),
    ThrottlerModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => [
        {
          ttl: 60000,
          limit: config.get('NODE_ENV') === 'production' ? 120 : 1000,
        },
      ],
    }),
    PrismaModule,
    EmailModule,
    StorageModule,
    PushModule,
    FirebaseModule,
    RealtimeModule,
    AuthModule,
    UsersModule,
    PostsModule,
    CommentsModule,
    MessagesModule,
    NotificationsModule,
    ReportsModule,
    AdminModule,
    ModerationModule,
    BotsModule,
    MediaModule,
  ],
  controllers: [HealthController],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
