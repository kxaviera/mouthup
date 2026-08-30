import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AccountType, Prisma, Profession } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateServiceCatalogDto } from './dto/create-service-catalog.dto';
import { UpdateServiceCatalogDto } from './dto/update-service-catalog.dto';

const PROVIDER_TYPES: AccountType[] = [
  AccountType.SERVICE_PROVIDER,
  AccountType.BOTH,
];

@Injectable()
export class ServiceCatalogService {
  constructor(private readonly prisma: PrismaService) {}

  private serialize(item: {
    id: string;
    profession: Profession;
    title: string;
    description: string | null;
    pricingType: string;
    price: Prisma.Decimal | null;
    currency: string;
    metadata: Prisma.JsonValue;
    city: string | null;
    active: boolean;
    sortOrder: number;
    createdAt: Date;
    updatedAt: Date;
    user?: {
      username: string | null;
      screenName: string | null;
      city: string | null;
      profession: Profession | null;
      isVerified: boolean;
      accountType: AccountType | null;
    };
  }) {
    return {
      id: item.id,
      profession: item.profession,
      title: item.title,
      description: item.description,
      pricingType: item.pricingType,
      price: item.price != null ? Number(item.price) : null,
      currency: item.currency,
      metadata: item.metadata ?? {},
      city: item.city,
      active: item.active,
      sortOrder: item.sortOrder,
      createdAt: item.createdAt.toISOString(),
      updatedAt: item.updatedAt.toISOString(),
      ...(item.user
        ? {
            providerUsername: item.user.username,
            providerScreenName: item.user.screenName,
            providerCity: item.user.city ?? item.city,
            providerProfession: item.user.profession,
            providerVerified: item.user.isVerified,
            providerAccountType: item.user.accountType ?? AccountType.SERVICE_PROVIDER,
          }
        : {}),
    };
  }

  private async assertProvider(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { accountType: true, bannedAt: true },
    });
    if (!user || user.bannedAt) {
      throw new ForbiddenException('Account not available');
    }
    if (!user.accountType || !PROVIDER_TYPES.includes(user.accountType)) {
      throw new ForbiddenException('Only service providers can manage a catalog');
    }
  }

  async search(params: {
    q?: string;
    profession?: Profession;
    city?: string;
    limit?: number;
  }) {
    const limit = Math.min(params.limit ?? 30, 50);
    const where: Prisma.ServiceCatalogItemWhereInput = {
      active: true,
      user: {
        bannedAt: null,
        username: { not: null },
        accountType: { in: PROVIDER_TYPES },
      },
    };

    if (params.profession) {
      where.profession = params.profession;
    }

    const city = params.city?.trim();
    if (city) {
      where.OR = [
        { city: { contains: city, mode: 'insensitive' } },
        { user: { city: { contains: city, mode: 'insensitive' } } },
      ];
    }

    const q = params.q?.trim();
    if (q) {
      const textFilter: Prisma.ServiceCatalogItemWhereInput = {
        OR: [
          { title: { contains: q, mode: 'insensitive' } },
          { description: { contains: q, mode: 'insensitive' } },
          { user: { screenName: { contains: q, mode: 'insensitive' } } },
          { user: { username: { contains: q, mode: 'insensitive' } } },
        ],
      };
      where.AND = where.AND
        ? [where.AND as Prisma.ServiceCatalogItemWhereInput, textFilter]
        : [textFilter];
    }

    const items = await this.prisma.serviceCatalogItem.findMany({
      where,
      include: {
        user: {
          select: {
            username: true,
            screenName: true,
            city: true,
            profession: true,
            isVerified: true,
            accountType: true,
          },
        },
      },
      orderBy: [{ sortOrder: 'asc' }, { createdAt: 'desc' }],
      take: limit,
    });

    return { items: items.map((item) => this.serialize(item)) };
  }

  async listByUsername(username: string) {
    const user = await this.prisma.user.findFirst({
      where: { username, bannedAt: null },
      select: { id: true, accountType: true },
    });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const items = await this.prisma.serviceCatalogItem.findMany({
      where: {
        userId: user.id,
        active: true,
      },
      orderBy: [{ sortOrder: 'asc' }, { createdAt: 'desc' }],
    });

    return { items: items.map((item) => this.serialize(item)) };
  }

  async create(userId: string, dto: CreateServiceCatalogDto) {
    await this.assertProvider(userId);

    const count = await this.prisma.serviceCatalogItem.count({
      where: { userId },
    });

    const item = await this.prisma.serviceCatalogItem.create({
      data: {
        userId,
        profession: dto.profession,
        title: dto.title.trim(),
        description: dto.description?.trim() || null,
        pricingType: dto.pricingType,
        price: dto.price != null ? dto.price : null,
        currency: dto.currency?.trim() || 'INR',
        metadata: (dto.metadata ?? {}) as Prisma.InputJsonValue,
        city: dto.city?.trim() || null,
        sortOrder: count,
      },
    });

    return this.serialize(item);
  }

  async update(userId: string, id: string, dto: UpdateServiceCatalogDto) {
    await this.assertProvider(userId);

    const existing = await this.prisma.serviceCatalogItem.findFirst({
      where: { id, userId },
    });
    if (!existing) {
      throw new NotFoundException('Service not found');
    }

    const item = await this.prisma.serviceCatalogItem.update({
      where: { id },
      data: {
        ...(dto.profession != null ? { profession: dto.profession } : {}),
        ...(dto.title != null ? { title: dto.title.trim() } : {}),
        ...(dto.description !== undefined
          ? { description: dto.description?.trim() || null }
          : {}),
        ...(dto.pricingType != null ? { pricingType: dto.pricingType } : {}),
        ...(dto.price !== undefined ? { price: dto.price } : {}),
        ...(dto.currency != null ? { currency: dto.currency.trim() } : {}),
        ...(dto.metadata != null
          ? { metadata: dto.metadata as Prisma.InputJsonValue }
          : {}),
        ...(dto.city !== undefined ? { city: dto.city?.trim() || null } : {}),
        ...(dto.active != null ? { active: dto.active } : {}),
      },
    });

    return this.serialize(item);
  }

  async remove(userId: string, id: string) {
    await this.assertProvider(userId);

    const existing = await this.prisma.serviceCatalogItem.findFirst({
      where: { id, userId },
    });
    if (!existing) {
      throw new NotFoundException('Service not found');
    }

    await this.prisma.serviceCatalogItem.delete({ where: { id } });
    return { ok: true };
  }
}
