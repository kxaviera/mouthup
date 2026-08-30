import { IsIn, IsString } from 'class-validator';

export class SupportReactionDto {
  @IsString()
  @IsIn(['HUG', 'STRENGTH', 'SAME'])
  type!: 'HUG' | 'STRENGTH' | 'SAME';
}
