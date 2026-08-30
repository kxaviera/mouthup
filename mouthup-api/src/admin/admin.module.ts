import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { ReportsModule } from '../reports/reports.module';
import { RealtimeModule } from '../realtime/realtime.module';

@Module({
  imports: [ReportsModule, RealtimeModule],
  controllers: [AdminController],
  providers: [AdminService],
  exports: [AdminService],
})
export class AdminModule {}
