# 스펙모아.zip 테스트 배포 순서

이 문서는 실제 앱스토어 배포 전, 테스트용 프로토타입을 휴대폰에 설치해서 검증하기 위한 순서입니다.

## 전체 흐름

```text
1. 로컬 PostgreSQL DB dump 생성
2. Supabase 프로젝트 생성
3. Supabase DB에 dump 복원
4. NestJS 서버를 외부 호스팅에 배포
5. Flutter 앱을 배포 서버 주소로 release APK 빌드
6. APK를 휴대폰에 설치해 테스트
```

## 1. 로컬 DB dump 생성

PostgreSQL 18 기준:

```powershell
cd C:\app_project
& "C:\Program Files\PostgreSQL\18\bin\pg_dump.exe" --dbname "<DATABASE_URL>" --format custom --file db\specmoa_DB.dump
```

현재 프로젝트에서는 `server/.env`의 `DATABASE_URL`을 사용해 dump를 만들면 됩니다.

## 2. Supabase DB 연결값

Supabase 프로젝트를 만든 뒤 아래 값을 확인합니다.

- Project URL
- Database host
- Database port
- Database name
- Database user
- Database password
- Connection string

서버 배포 환경변수에는 보통 아래처럼 넣습니다.

```env
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://postgres:<PASSWORD>@<HOST>:5432/postgres
DB_SCHEMA=public
DB_SYNC=false
DB_SSL=true
QNET_SERVICE_KEY=<공공데이터_인증키>
```

## 3. Supabase에 dump 복원

Supabase connection string을 받은 뒤:

```powershell
& "C:\Program Files\PostgreSQL\18\bin\pg_restore.exe" --dbname "<SUPABASE_DATABASE_URL>" --clean --if-exists db\specmoa_DB.dump
```

## 4. 서버 배포

테스트 배포는 Render Free Web Service를 기준으로 진행합니다.

### 4-1. GitHub 저장소 준비

Render는 GitHub, GitLab, Bitbucket 저장소를 연결해서 배포합니다.

```powershell
cd C:\app_project
git init
git add .
git commit -m "Prepare specmoa prototype deployment"
```

그 다음 GitHub에서 새 repository를 만들고 원격 저장소로 push합니다.

### 4-2. Render 서비스 생성

1. Render 회원가입 또는 로그인
2. Dashboard에서 `New +`
3. `Blueprint` 또는 `Web Service` 선택
4. GitHub 저장소 연결
5. 루트의 `render.yaml`을 사용하거나 아래 값을 직접 입력

직접 입력할 경우:

```text
Name: specmoa-api
Runtime: Node
Root Directory: server
Build Command: npm install && npm run build
Start Command: npm run start:prod
Instance Type: Free
Health Check Path: /health
```

### 4-3. Render 환경변수

Render의 `Environment`에 아래 값을 추가합니다.

```env
NODE_ENV=production
DATABASE_URL=<SUPABASE_POOLER_DATABASE_URL>
DB_SCHEMA=public
DB_SYNC=false
DB_SSL=true
CORS_ORIGIN=
QNET_SERVICE_KEY=<QNET_SERVICE_KEY>
```

나머지 QNET URL은 `render.yaml`에 기본값으로 들어 있습니다.

서버 배포 명령은 Render가 자동으로 실행합니다.

```bash
npm install
npm run build
npm run start:prod
```

배포 후 헬스 체크:

```text
https://<your-api-host>/health
```

## 5. Flutter 테스트 APK 빌드

서버 배포 URL을 넣어서 빌드합니다.

```powershell
cd C:\app_project\ui
flutter build apk --release --dart-define=API_BASE_URL=https://<your-api-host>
```

빌드 결과:

```text
ui\build\app\outputs\flutter-apk\app-release.apk
```

이 APK를 휴대폰에 설치해서 테스트하면 됩니다.

## 주의

- 테스트 APK가 로컬 PC IP나 `localhost`를 바라보면 외부 환경에서 동작하지 않습니다.
- 서버 배포 환경에서는 `DB_SYNC=false`를 권장합니다.
- Supabase 연결은 `DB_SSL=true`가 필요합니다.
