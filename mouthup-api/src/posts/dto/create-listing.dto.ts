import { Type } from 'class-transformer';
import {
  IsArray,
  IsEnum,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  ValidateNested,
} from 'class-validator';
import { Profession } from '@prisma/client';

class MediaItemDto {
  @IsString()
  @IsIn(['IMAGE', 'VIDEO'])
  type!: 'IMAGE' | 'VIDEO';

  @IsString()
  url!: string;
}

export class CreateListingDto {
  @IsString()
  title!: string;

  @IsString()
  content!: string;

  @IsString()
  @IsIn(['SALE', 'RENT', 'SWAP', 'GIVEAWAY', 'SERVICE', 'SERVICE_REQUEST'])
  listingType!: 'SALE' | 'RENT' | 'SWAP' | 'GIVEAWAY' | 'SERVICE' | 'SERVICE_REQUEST';

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  price?: number;

  @IsOptional()
  @IsString()
  currency?: string;

  @IsOptional()
  @IsString()
  @IsIn(['DAY', 'WEEK', 'MONTH'])
  rentPeriod?: 'DAY' | 'WEEK' | 'MONTH';

  @IsOptional()
  @IsString()
  swapFor?: string;

  @IsOptional()
  @IsString()
  location?: string;

  @IsOptional()
  @IsEnum(Profession)
  requestedProfession?: Profession;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => MediaItemDto)
  media?: MediaItemDto[];
}

export class ListingStatusDto {
  @IsString()
  @IsIn(['OPEN', 'CLOSED'])
  status!: 'OPEN' | 'CLOSED';
}
