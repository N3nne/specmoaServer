# specmoa.zip

해당 프로젝트는 2개의 폴더로 나누어집니다.

```text
ui/       플러터 프로젝트로 작성된 앱의 UI 부분입니다.
server/   앱의 서버입니다. Nest.js, TypeORM, postgreSQL 과 연동하여 사용합니다
docs/     공통 디자인 및 아키텍쳐
```

## Release
```text

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

서버는 다음과 같은 핵심 리소스로 시작합니다.

- 외부 API 동기화를 통한 자격증 및 시험 일정
- 사용자별 자격증 관리
- 학습 세션

초기 로컬 개발 환경에서는 사용자 범위 서버 엔드포인트에 `x-user-id`를 사용합니다. `x-user-id`가 없으면 서버는 데모 사용자를 사용합니다.
