# specmoa.zip

This repository is split into two apps:

```text
ui/       Flutter mobile UI based on the Stitch specmoa.zip design
server/   NestJS API server backed by PostgreSQL and TypeORM
docs/     Shared planning and architecture notes
```

## UI

```bash
cd ui
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

## Server

```bash
cd server
npm install
copy .env.example .env
npm run start:dev
```

The server starts with these core resources:

- Certifications and exam schedules from external API sync
- User-specific certification tracking
- Study tasks
- Study sessions

For early local development, user-scoped server endpoints use `x-user-id`; without it, the server falls back to a demo user.
