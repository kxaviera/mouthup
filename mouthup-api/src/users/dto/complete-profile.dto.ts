import { IsIn, IsOptional, IsString, MinLength } from 'class-validator';

export class CompleteProfileDto {
  @IsString()
  @IsIn(['BUYER', 'SELLER', 'BOTH', 'SERVICE_PROVIDER'])
  accountType!: 'BUYER' | 'SELLER' | 'BOTH' | 'SERVICE_PROVIDER';

  @IsOptional()
  @IsString()
  @IsIn([
    'PLUMBER',
    'ELECTRICIAN',
    'CHEF',
    'PAINTER',
    'CARPENTER',
    'AC_REPAIR',
    'CLEANER',
    'DRIVER',
    'TUTOR',
    'MECHANIC',
    'GARDENER',
    'BEAUTICIAN',
    'PHOTOGRAPHER',
    'OTHER',
  ])
  profession?: string;

  @IsOptional()
  @IsString()
  @MinLength(2)
  city?: string;
}
