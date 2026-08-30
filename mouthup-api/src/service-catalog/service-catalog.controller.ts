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
import { ServiceCatalogService } from './service-catalog.service';
import { SearchServiceCatalogDto } from './dto/search-service-catalog.dto';
import { CreateServiceCatalogDto } from './dto/create-service-catalog.dto';
import { UpdateServiceCatalogDto } from './dto/update-service-catalog.dto';
import { JwtAuthGuard, OptionalJwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { VerifiedUserGuard } from '../common/guards/admin.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/types/auth-user';

@Controller('service-catalog')
export class ServiceCatalogController {
  constructor(private readonly catalog: ServiceCatalogService) {}

  @Get('search')
  @UseGuards(OptionalJwtAuthGuard)
  search(@Query() query: SearchServiceCatalogDto) {
    return this.catalog.search({
      q: query.q,
      profession: query.profession,
      city: query.city,
      limit: query.limit,
    });
  }

  @Get('users/:username')
  listByUser(@Param('username') username: string) {
    return this.catalog.listByUsername(username);
  }

  @Post('me')
  @UseGuards(JwtAuthGuard, VerifiedUserGuard)
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateServiceCatalogDto) {
    return this.catalog.create(user.id, dto);
  }

  @Patch('me/:id')
  @UseGuards(JwtAuthGuard, VerifiedUserGuard)
  update(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: UpdateServiceCatalogDto,
  ) {
    return this.catalog.update(user.id, id, dto);
  }

  @Delete('me/:id')
  @UseGuards(JwtAuthGuard, VerifiedUserGuard)
  remove(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.catalog.remove(user.id, id);
  }
}
