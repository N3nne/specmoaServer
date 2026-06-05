# UI / Server Split Plan

This project is now split into two top-level apps:

```text
project/
  ui/       # Flutter app
  server/   # NestJS API
  docs/     # shared design and architecture notes
```

## Current State

- Flutter files live in `ui/`.
- The NestJS backend lives in `server/`.
- UI is still mostly driven by local mock data in `ui/lib/models/mock_data.dart`.
- Design source of truth is `DESIGN.md`.
- The server has PostgreSQL/TypeORM entities for users, certifications, exam schedules, study tasks, and study sessions.

## UI App

```text
ui/
  pubspec.yaml
  analysis_options.yaml
  lib/
  test/
```

## Server App

```text
server/
  package.json
  src/
    main.ts
    app.module.ts
    certifications/
    study-sessions/
    study-tasks/
    users/
```

Keep shared planning docs at the root:

```text
DESIGN.md
docs/ui_server_split_plan.md
```

## Flutter Preparation Rules

- Screens should not call HTTP directly.
- Screens should depend on repository/service classes later.
- Mock data should remain isolated in `models/mock_data.dart` until replaced.
- All API URLs should be derived from `AppConfig.apiBaseUrl`.
- Use `--dart-define=API_BASE_URL=http://localhost:3000` for local server wiring.

## Nest API Boundary

Suggested first API resources:

- `GET /health`
- `GET /certifications`
- `GET /certifications/:id`
- `POST /certifications/sync`
- `POST /certifications/user`
- `GET /study-tasks/today`
- `POST /study-tasks`
- `PATCH /study-tasks/:id/complete`
- `GET /study-sessions/today`
- `POST /study-sessions`

Suggested later resources:

- `auth`
- `users`
- `exam-schedules`
- `achievements`
- `statistics`

## Data Contract Direction

Keep DTO names close across Flutter and Nest:

- Flutter model: `Certification`
- Nest DTO: `CertificationDto`
- Flutter model: `StudyTask`
- Nest DTO: `StudyTaskDto`

Avoid leaking database field names into Flutter. The server should transform persistence models into stable DTOs.

## Environment Strategy

Flutter:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

Nest:

```bash
cd server
npm install
copy .env.example .env
npm run start:dev
```

## Migration Checklist

1. Done: Move Flutter files into `ui/`.
2. Done: Create NestJS app in `server/`.
3. Done: Add CORS for Flutter local development.
4. Done: Create first DTOs and entities in Nest.
5. Next: Install server dependencies and connect a local PostgreSQL database.
6. Next: Replace `mock_data.dart` usage with repository calls screen by screen.
7. Next: Add authentication and replace demo user fallback.
