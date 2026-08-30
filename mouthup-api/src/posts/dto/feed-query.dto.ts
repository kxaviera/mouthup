import { IsIn, IsOptional, IsString } from 'class-validator';
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
}
