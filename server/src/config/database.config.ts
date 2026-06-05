import { TypeOrmModuleOptions } from '@nestjs/typeorm';

export function databaseConfig(): TypeOrmModuleOptions {
  const databaseUrl = process.env.DATABASE_URL;
  const useSsl = process.env.DB_SSL === 'true';

  if (!databaseUrl) {
    throw new Error(
      'DATABASE_URL is missing. Create server/.env from .env.example and set your PostgreSQL connection string.',
    );
  }

  return {
    type: 'postgres',
    url: databaseUrl,
    schema: process.env.DB_SCHEMA || 'public',
    autoLoadEntities: true,
    synchronize: process.env.DB_SYNC === 'true',
    logging: process.env.NODE_ENV !== 'production',
    ssl: useSsl ? { rejectUnauthorized: false } : false,
  };
}
