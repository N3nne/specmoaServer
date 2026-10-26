import { UnauthorizedException } from '@nestjs/common';

export const VERIFIED_USER_ID = Symbol('verifiedUserId');

export function getUserIdFromHeaders(headers: Record<string, unknown>) {
  const value: unknown = Reflect.get(headers, VERIFIED_USER_ID);
  if (typeof value === 'string' && value.length > 0) return value;
  throw new UnauthorizedException('로그인이 필요합니다.');
}
