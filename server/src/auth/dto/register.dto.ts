import { IsEmail, IsString, MaxLength, MinLength } from 'class-validator';

export class RegisterDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(2)
  @MaxLength(30)
  displayName: string;

  @IsString()
  @MinLength(8)
  password: string;
}
