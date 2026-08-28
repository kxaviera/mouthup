import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Query,
  UseGuards,
} from '@nestjs/common';
import { IsEnum, IsOptional, IsString } from 'class-validator';
import { ReportStatus } from '@prisma/client';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { AdminGuard } from '../common/guards/admin.guard';

class ResolveReportDto {
  @IsEnum(ReportStatus)
  status!: ReportStatus;

  @IsOptional()
  @IsString()
  adminNote?: string;
}

class BanUserDto {
  @IsString()
  reason!: string;
}

@Controller('admin')
@UseGuards(JwtAuthGuard, AdminGuard)
export class AdminController {
  constructor(private readonly admin: AdminService) {}

  @Get('dashboard')
  dashboard() {
    return this.admin.dashboard();
  }

  @Get('reports')
  reports(@Query('limit') limit?: string) {
    return this.admin.pendingReports(limit ? Number(limit) : 50);
  }

  @Patch('reports/:id')
  resolve(@Param('id') id: string, @Body() dto: ResolveReportDto) {
    return this.admin.resolveReport(id, dto.status, dto.adminNote);
  }

  @Get('users')
  searchUsers(@Query('q') q: string) {
    return this.admin.searchUsers(q ?? '');
  }

  @Patch('users/:id/ban')
  ban(@Param('id') id: string, @Body() dto: BanUserDto) {
    return this.admin.banUser(id, dto.reason);
  }

  @Patch('users/:id/unban')
  unban(@Param('id') id: string) {
    return this.admin.unbanUser(id);
  }

  @Delete('posts/:id')
  deletePost(@Param('id') id: string) {
    return this.admin.deletePost(id);
  }

  @Get('posts')
  searchPosts(@Query('q') q: string) {
    return this.admin.searchPosts(q ?? '');
  }
}
