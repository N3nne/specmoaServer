# v0.2.0 프로토타입 배포 기록

시작일: 2026-10-27, Asia/Seoul

## 범위와 승인

- 기존 0.1.x는 보존하고 다음 버전 0.2.0으로 코드와 APK를 저장한다.
- GitHub 저장소: `N3nne/specmoaServer`.
- 별도 소스 브랜치: `specmoa_ver2(0.2.0)` (사용자 요청으로 `codex/prototype-v0.2.0`에서 변경). main 자동 배포와 분리한다.
- 클라우드 호환성·휴대폰 검증 전에는 APK를 검증 완료 버전으로 공개하지 않는다.
- UI를 새로 만들거나 실제 사용자 정보를 Gemini에 전송하지 않는다.

## 확인된 상태

- 기존 원격 main 변경은 README뿐이었으며 fast-forward로 보존했다.
- GitHub 인증과 저장소 쓰기 권한 확인, 새 브랜치 push dry-run 통과.
- 기존 Render `/health`는 200이지만 `/career/occupations`는 404다. 새 API가 아직 배포되지 않았다.
- 현재 `server/.env`는 로컬 PostgreSQL을 사용한다. Supabase 접속 정보는 별도 준비가 필요하다.
- release 빌드는 기존 테스트 서명(debug key)을 사용한다. 스토어용 정식 서명이 아니다.
- Flutter 버전은 `0.2.0+4`, 서버 패키지는 `0.2.0`으로 올렸다.

## 체크리스트

- [x] 원격 변경·인증·버전 점검.
- [x] 새 브랜치 생성 및 원격 README 보존.
- [x] 로컬 전용 클라우드 설정 파일 준비 및 Git 제외 확인.
- [x] Android APK 빌드 및 패키지/서명/서버 주소 점검.
- [x] 변경 파일·비밀정보 점검, 앱/서버 소스 커밋·버전 브랜치 푸시.
- [x] GitHub v0.2.0 초안 릴리즈에 APK와 SHA-256 저장.
- [x] Supabase 백업·스키마 확인·필요 마이그레이션·가상 공고 준비.
- [x] Render 최신 서버 배포 및 실제 API 호환성 확인.
- [ ] 실기기 검증 후 공개 다운로드·QR 준비.

## 클라우드 접속 정보

`server/.env.prototype.local`은 Git에서 제외되며 기본 로컬 `.env`를 덮어쓰지 않는다.
사용자가 현재 Supabase Session pooler의 전체 `DATABASE_URL`을 이 파일에 입력한다.
이 파일의 원문이나 연결 문자열을 출력하지 않는다. 값이 준비되어도 DB 백업과 대상 확인 전에는 마이그레이션하지 않는다.

현재 Render는 main 기준으로 기존 버전을 서비스한다. 새 브랜치에 푸시하는 것만으로 Render가 업데이트되었다고 간주하면 안 된다.
새 API와 새 APK를 함께 반영하기 전에는 기존 APK/서버 간 인증 호환성이 달라질 수 있다.

## 포함/제외

포함: 로그인 세션, 8종 스펙 관리, 자유 학습/스펙 연결 타이머, 가상 채용공고와 규칙 기반 조건 비교, 분석 준비 API/클라이언트.

제외: 미제공 희망 직무 UI, 실제 사용자 개인화 AI, 운영 환경 AI 시연, 실제 채용 API, 정식 스토어 배포.

`.env`, 로컬 클라우드 설정, DB dump, keystore, APK 빌드 폴더, CalendarApp 등 다른 프로젝트는 소스 커밋에서 제외한다.

## 빌드·검증 결과

- `flutter build apk --release --no-pub --dart-define=API_BASE_URL=https://specmoa-api.onrender.com --build-name=0.2.0 --build-number=4`: 성공.
- 패키지 `com.example.specmoa_zip_ui`, 버전 `0.2.0`, versionCode `4`, 앱 이름 `스펙모아.zip`.
- Android API 24 이상, arm64-v8a / armeabi-v7a / x86_64 포함.
- 실행 Activity 포함 및 APK 서명 검증 통과. 기존 개발용 Android Debug 서명이며 정식 배포 서명은 아니다.
- APK에 Render HTTPS 주소가 들어 있고 로컬 API 주소가 들어 있지 않은 것을 확인했다.
- 서버 빌드 및 62개 테스트, Flutter 120개 테스트, Flutter 정적 분석 통과.
- 커밋 후보 129개 파일 검사에서 설정된 비밀정보·키 패턴·DB 접속 문자열·금지 산출물을 찾지 못했다.
- USB 기기가 연결되어 있지 않아 이번 APK의 휴대폰 설치/동작 확인은 아직 하지 않았다.

## 클라우드 안전 상태

사용자는 기존 Supabase를 백업한 뒤 테이블을 추가하는 방식을 선택했다.
처음 제공된 접속 설정이 localhost를 가리켜 안전 검사에서 중단했으며, 이 시점에는 Supabase에 접속하거나 데이터를 변경하지 않았다.
Supabase 주소 수정 후 읽기 전용 점검, public 스키마 백업, 로컬 임시 DB 복원 검증, 필요한 마이그레이션 순서로 진행한다.

Render 설정에는 가상 공고 사용을 명시하고(`JOBS_SOURCE=demo`) 외부 AI 시연은 비활성화했다.
이는 소스 설정이며, 기존 Render 서비스의 실행 환경이 이미 갱신되었다는 뜻은 아니다.

## GitHub 저장 완료

- 소스 커밋: `8d7a744` (`Prepare v0.2.0 spec management prototype`).
- 소스: https://github.com/N3nne/specmoaServer/tree/specmoa_ver2%280.2.0%29
- 초안 릴리즈 ID: `424470818`, 태그 예정 이름 `v0.2.0-prototype`.
- 초안: https://github.com/N3nne/specmoaServer/releases/tag/untagged-de4edeb0f9a21e846de9
- 초안이므로 저장소 소유자 권한으로 확인하며, 공개 다운로드/QR은 아직 제공하지 않는다.
- APK: `release/specmoa-prototype-v0.2.0.apk`, 56,216,218 bytes.
- APK SHA-256: `3e6f5aa44f2d5a993303e7fedf0cbe1cd8e4728c8b5e5f715a4356edc850cd24`.
- APK와 SHA-256 파일을 초안에 업로드했고 GitHub가 반환한 APK digest가 로컬 해시와 일치했다.

## 이전 인증 문제 (해결)

Supabase 주소 수정 후에는 승인된 기존 프로젝트의 Session pooler에 도달했으나 비밀번호 인증이 `28P01`로 거절됐다.
자동 반복 접속을 중단했다. 클라우드 백업·마이그레이션·가상 공고 입력·Render 배포는 아직 수행하지 않았다.
사용자가 DB 비밀번호 확인 위치를 질문했으며, 다음 답변에서 Render에 저장된 DATABASE_URL 확인 또는 Supabase Database > Settings 비밀번호 재설정 경로를 안내한다.

사용자가 접속 정보를 다시 수정하여 이 인증 문제는 해결됐다. 아래의 Supabase 업데이트 완료 상태와 다음 재개 지점을 따른다.

관련 실행 세션은 모두 완료했다. Android 휴대폰은 현재 연결되지 않았다.

## Supabase 업데이트 완료 (2026-10-27)

- 수정된 접속 설정으로 승인된 기존 프로젝트(PostgreSQL 17.6)에 연결했다.
- 같은 PostgreSQL 스냅샷에서 public 스키마의 19개 테이블을 백업했다. Auth/Storage 등 다른 스키마를 포함하는 전체 Supabase 프로젝트 백업은 아니다.
- 백업: `db/supabase_public_before_v0.2.0_20261027_83d16d3a.dump` (641,755 bytes, Git 제외).
- SHA-256: `2e10842f4434691fb23c0781795a322cc050dfbe80ad66d885ced1af2a54f593`.
- 로컬의 새 무작위 이름 임시 DB에 복원하고 기존 19개 테이블의 건수·ID·모든 기존 필드 내용 해시가 일치하는지 확인했다.
- 복원 시 public의 `uuid-ossp` 확장을 먼저 준비하고, 사전 생성한 public 스키마의 CREATE SCHEMA 항목만 아카이브 실행 목록에서 제외했다. 원본 dump는 변경하지 않았다.
- 복원 사본에서 마이그레이션 3개를 먼저 검증한 후 실제 Supabase에 같은 3개를 트랜잭션으로 적용했다. `DB_SYNC`/자동 동기화는 사용하지 않았다.
- `user_specs`, `auth_sessions`, `job_postings`, TypeORM `migrations` 관리 테이블 추가 및 `study_sessions.specId` 추가.
- 기존 취득 자격증 5건을 `user_specs`로 복사했다. 원본 `user_certifications` 11건을 비롯한 기존 19개 테이블의 기존 필드 내용이 모두 보존됐음을 재검증했다.
- 새 `job_postings`에만 demo/synthetic 공고 40건 저장. 실제 공고나 지원 가능한 공고로 표시하지 않는다.
- 상세 검증 메타데이터는 비밀정보 없이 로컬 `.buildlog/supabase-backup-state.json`에 저장했다.
- Render 최신 코드 배포와 APK 실기기 검증은 아직 남아 있다. GitHub 릴리즈는 계속 초안이다.

## Render 배포 진행 기록 (완료)

2026-10-27 추가 승인 및 진행: Render 연동을 연결했고 사용자가 `nne's workspace`의 기존 무료 `specmoa-api` 서비스를 확인했다. 서비스는 main 자동 배포이며 연동 도구가 브랜치 변경을 지원하지 않아, 사용자가 v0.2.0을 main에 반영하고 자동 배포하는 방식을 명시적으로 승인했다. 아래의 codex 브랜치 직접 지정 계획은 이 승인으로 대체한다.

- Render 서비스 `srv-d8hdve6gvqtc73d6493g`, 워크스페이스 `tea-d8hdu528qa3s73bjfehg`.
- 기존 요금제 free, URL `https://specmoa-api.onrender.com`, rootDir `server`, main 커밋 자동 배포 확인.
- 기존 환경변수를 삭제하지 않는 병합 방식으로 유효한 DATABASE_URL과 production/public/SSL=true/DB_SYNC=false/JOBS_SOURCE=demo/AI_DEMO_ENABLED=false를 반영했다.
- 기존 JWT_SECRET은 덮어쓰지 않았다. 새 서버 시작 시 요구 조건을 충족하지 않으면 배포 로그로 확인하고 필요한 경우에만 안전하게 보완한다.
- 기존 성공 배포 `dep-d8hebbnlk1mc73ef2jkg`, 커밋 `1cfe16e93ccd3d6a43a65f862e6c77f3ada6934b`를 복구 참고로 보존한다.
- 다음 단계: main fast-forward 푸시로 발생한 자동 배포를 추적한다. 같은 배포를 중복 요청하지 않는다.

- 브라우저 제어 오류는 우회하지 않았다. 사용자가 Render 연동을 연결한 뒤 승인된 워크스페이스의 기존 서비스를 정상 API로 조회·설정했다.
- 사용자가 main 반영을 명시적으로 승인했고, 원격 main의 기존 커밋을 보존하는 fast-forward로 v0.2.0을 반영했다.
- main은 자동 배포다. 환경변수 갱신에 따른 도구의 재배포 뒤, 새 소스의 Blueprint 동기화 배포가 실행됐다. 수동 trigger_deploy를 추가 호출하지 않았다.
- DB 마이그레이션·공고 입력을 다시 실행하거나 DB를 초기화하지 않았다.
- 로컬 임시 복원 DB와 검증 계정은 정리했으며 백업은 보존했다.

## Render 배포·실제 API 검증 완료

- 정상 실행 배포: `dep-dbfnvnmdjanc73aetnng` / 상태 `live`.
- 실행 커밋: `f49958cd9141ff2caf184cfa5a777517432a5c57` (main).
- 배포 완료: 2026-10-27 01:30 KST. 서버 패키지 0.2.0, Node.js 22.23.4.
- 주소: https://specmoa-api.onrender.com
- 기존 서비스·주소·free 요금제·Supabase 데이터를 유지했다.
- 실제 Render API에서 41개 검증 통과: 인증 없는 요청 차단, 가입/로그인, 선택 입력 스펙 8종 CRUD, 소유권 분리, 희망 직무 저장, 분석 원본/수정 반영, 가상 공고 40건, 규칙 기반 조건 비교, 학습 기록 누적/삭제, 토큰 교체/재사용 차단/로그아웃.
- 운영 환경 AI 시연이 비활성화돼 있음을 확인했으며 실제 사용자 데이터를 외부 AI에 전송하지 않았다.
- 임시 QA 계정 2개와 연결 스펙·학습·세션을 정리했다. 임시 데이터 0건 확인.
- 최종 데이터: 기존 사용자 5명, 취득 스펙 5건, 기존 학습 기록 7건, 가상 공고 40건. 기존 19개 테이블의 모든 기존 필드 내용도 다시 비교해 변경이 없음을 확인했다.
- 검증 상세: 로컬 `.buildlog/render-rollout-state.json`, `.buildlog/render-live-qa-state.json` (토큰/비밀번호 없음).
- 기존 APK의 인증 방식은 호환되지 않을 수 있으므로 v0.2.0 APK로 테스트한다. 이번 단계에서는 앱 코드를 변경하지 않아 APK 재빌드는 하지 않았다.

## 남은 범위와 주의

- 휴대폰 설치/실행 검증 후 APK 초안 공개·다운로드 QR 진행. 현재 GitHub 릴리즈는 계속 초안이다.
- 현재는 프로토타입이다. 로그인 요청 제한·실제 비밀번호 재설정 메일·개인화 AI 등 미완료 범위는 그대로 남아 있다.
- 배포 로그의 의존성 경고를 별도로 확인했다. `npm audit --omit=dev --json` 기준 런타임 의존성 경고 11개(높음 4, 보통 7, 치명적 0)가 남아 있다. 관련 패키지는 @nestjs/platform-express, body-parser, lodash, multer 등이며 정식 공개 전에 우선 보완해야 한다.
- 감사 도구가 메이저 버전 변경을 포함한 해결책을 제시하므로 이번 배포에서 `npm audit fix --force`를 실행하지 않았다. 별도 변경·회귀 검증이 필요하다.
- 이 검증 기록만 저장하는 후속 커밋에는 `[skip render]`를 사용해 불필요한 자동 재배포를 생략한다. [Render 공식 안내](https://render.com/docs/deploys#skipping-an-auto-deploy)

## 휴대폰 설치 및 브랜치 변경 요청 (2026-10-27)

- GitHub와 로컬 버전 브랜치를 `specmoa_ver2(0.2.0)`으로 변경하고 원격 추적도 갱신했다. 기존 main과 Render 배포는 변경하지 않았다.
- 기존 릴리스 ID `424470818`의 APK와 체크섬은 uploaded 상태이며 APK digest가 로컬 SHA-256과 일치한다. 같은 파일을 중복 업로드하지 않았다.
- 릴리스 대상 브랜치를 새 이름으로 갱신했다. 예정 태그는 `v0.2.0-prototype`이며, 공개 여부 확인 전에는 초안을 유지한다.
- Windows에 삼성 S24가 연결되어 있지만 ADB 기기는 아직 감지되지 않는다. USB 디버깅 허용을 요청했으며 설치/실행 검증은 미완료다.
