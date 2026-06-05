# specmoa.zip Server

NestJS API server for the Flutter UI in `../ui`.

## Stack

- NestJS
- PostgreSQL
- TypeORM

## Local Run

```bash
cd server
npm install
copy .env.example .env
npm run start:dev
```

`DB_SYNC=true` is only for early local development. Replace it with migrations before production.

If you created a dedicated PostgreSQL schema, set it with:

```env
DB_SCHEMA=specmoa_db
```

## First API Surface

- `GET /health`
- `GET /certifications`
- `GET /certifications/:id`
- `POST /certifications/sync`
- `GET /study-tasks/today`
- `POST /study-tasks`
- `PATCH /study-tasks/:id/complete`
- `GET /study-sessions/today`
- `POST /study-sessions`

During early development, user-scoped endpoints accept `x-user-id`. If omitted, the server creates/uses a demo user.
