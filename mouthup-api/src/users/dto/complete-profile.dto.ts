import { IsIn, IsOptional, IsString, MinLength } from 'class-validator';

const PROFESSIONS = [
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
  'MAID',
  'NURSE',
  'PEST_CONTROL',
  'BABYSITTER',
  'ELDER_CARE',
  'TAILOR',
  'LAUNDRY',
  'SECURITY',
  'EVENT_PLANNER',
  'PHYSIO',
  'OTHER',
] as const;

export class CompleteProfileDto {
  @IsString()
  @IsIn(['BUYER', 'SELLER', 'BOTH', 'SERVICE_PROVIDER'])
  accountType!: 'BUYER' | 'SELLER' | 'BOTH' | 'SERVICE_PROVIDER';

  @IsOptional()
  @IsString()
  @IsIn(PROFESSIONS)
  profession?: string;

  @IsOptional()
  @IsString()
  @MinLength(2)
  city?: string;
}
