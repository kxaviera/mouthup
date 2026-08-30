import {
  IsEmail,
  IsNotEmpty,
  IsString,
  MinLength,
} from 'class-validator';

export class RegisterDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(6)
  password!: string;
}

export class LoginDto {
  /** Email address or username */
  @IsString()
  @IsNotEmpty()
  login!: string;

  @IsString()
  @IsNotEmpty()
  password!: string;
}

export class VerifyEmailDto {
  @IsString()
  @MinLength(6)
  code!: string;
}

export class RefreshTokenDto {
  @IsString()
  @IsNotEmpty()
  refreshToken!: string;
}

export class ForgotPasswordDto {
  @IsEmail()
  email!: string;
}

export class ResetPasswordDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(6)
  code!: string;

  @IsString()
  @MinLength(6)
  newPassword!: string;
}

export class FirebaseLoginDto {
  @IsString()
  @IsNotEmpty()
  idToken!: string;
}
