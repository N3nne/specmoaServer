# specmoa.zip

This repository is split into two apps:

```text
ui/       플러터 프로젝트로 작성된 앱의 UI 부분입니다.
server/   앱의 서버입니다. Nest.js, TypeORM, postgreSQL 과 연동하여 사용합니다
docs/     Shared planning and architecture notes


release 0.1.0 : 구현 완료된 내용을 apk 파일로 첫 구현
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
