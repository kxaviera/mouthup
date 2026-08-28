import { Body, Controller, Param, Post, UseGuards } from '@nestjs/common';
import { IsString } from 'class-validator';
import { ReportsService } from './reports.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/types/auth-user';

class ReportDto {
  @IsString()
  reason!: string;
}

@Controller()
export class ReportsController {
  constructor(private readonly reports: ReportsService) {}

  @Post('posts/:id/report')
  @UseGuards(JwtAuthGuard)
  reportPost(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: ReportDto,
  ) {
    return this.reports.reportPost(user.id, id, dto.reason);
  }

  @Post('users/:username/report')
  @UseGuards(JwtAuthGuard)
  reportUser(
    @CurrentUser() user: AuthUser,
    @Param('username') username: string,
    @Body() dto: ReportDto,
  ) {
    return this.reports.reportUser(user.id, username, dto.reason);
  }

  @Post('comments/:id/report')
  @UseGuards(JwtAuthGuard)
  reportComment(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: ReportDto,
  ) {
    return this.reports.reportComment(user.id, id, dto.reason);
  }
}
