import { IsIn, IsOptional, IsString } from 'class-validator';
import { Type } from 'class-transformer';
import { CursorPaginationDto } from '../../common/dto/cursor-pagination.dto';

export class FeedQueryDto extends CursorPaginationDto {
  @IsOptional()
  @IsString()
  hashtag?: string;

  @IsOptional()
  @IsString()
  q?: string;

  @IsOptional()
  @IsString()
  @IsIn(['SALE', 'RENT', 'SWAP', 'GIVEAWAY', 'SERVICE', 'SERVICE_REQUEST'])
  listingType?: 'SALE' | 'RENT' | 'SWAP' | 'GIVEAWAY' | 'SERVICE' | 'SERVICE_REQUEST';

  @IsOptional()
  @IsString()
  city?: string;

  @IsOptional()
  @IsString()
  @IsIn(['for_you', 'following', 'nearby', 'explore'])
  feedMode?: 'for_you' | 'following' | 'nearby' | 'explore';

  @IsOptional()
  @Type(() => Number)
  radiusKm?: number;
}
