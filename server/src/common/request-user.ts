import { BadRequestException } from '@nestjs/common';

export function getUserIdFromHeaders(headers: Record<string, unknown>) {
  const value = headers['x-user-id'];

  if (Array.isArray(value)) {
    return value[0];
  }

  if (typeof value === 'string' && value.trim().length > 0) {
    return value.trim();
  }

  if (value == null) {
    return undefined;
  }

  throw new BadRequestException('x-user-id must be a string when provided.');
}
