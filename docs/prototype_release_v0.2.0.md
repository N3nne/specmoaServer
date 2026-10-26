# v0.2.0 프로토타입 배포 기록

시작일: 2026-10-27, Asia/Seoul

## 범위와 승인

- 기존 0.1.x는 보존하고 다음 버전 0.2.0으로 코드와 APK를 저장한다.
- GitHub 저장소: `N3nne/specmoaServer`.
- 별도 소스 브랜치: `codex/prototype-v0.2.0`. main 자동 배포와 분리한다.
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
- [ ] Supabase 백업·스키마 확인·필요 마이그레이션·가상 공고 준비.
- [ ] Render 최신 서버 배포 및 호환성 확인.
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
- 소스: https://github.com/N3nne/specmoaServer/tree/codex/prototype-v0.2.0
- 초안 릴리즈 ID: `424470818`, 태그 예정 이름 `v0.2.0-prototype`.
- 초안: https://github.com/N3nne/specmoaServer/releases/tag/untagged-7f71cd963a4741b9892d
- 초안이므로 저장소 소유자 권한으로 확인하며, 공개 다운로드/QR은 아직 제공하지 않는다.
- APK: `release/specmoa-prototype-v0.2.0.apk`, 56,216,218 bytes.
- APK SHA-256: `3e6f5aa44f2d5a993303e7fedf0cbe1cd8e4728c8b5e5f715a4356edc850cd24`.
- APK와 SHA-256 파일을 초안에 업로드했고 GitHub가 반환한 APK digest가 로컬 해시와 일치했다.

## 현재 재개 지점

Supabase 주소 수정 후에는 승인된 기존 프로젝트의 Session pooler에 도달했으나 비밀번호 인증이 `28P01`로 거절됐다.
자동 반복 접속을 중단했다. 클라우드 백업·마이그레이션·가상 공고 입력·Render 배포는 아직 수행하지 않았다.
사용자가 DB 비밀번호 확인 위치를 질문했으며, 다음 답변에서 Render에 저장된 DATABASE_URL 확인 또는 Supabase Database > Settings 비밀번호 재설정 경로를 안내한다.

비밀번호 수정 완료라는 새 응답을 받으면 파일을 다시 읽고 한 번 접속을 확인한다. 기존 잘못된 비밀번호를 다시 시도하지 않는다.
백업은 앱 public 스키마의 백업이라는 범위를 명시하고, 로컬 격리 DB 복원 검증 후에만 필요한 마이그레이션을 적용한다.
Render는 여전히 기존 main 버전이다. API 404가 없어졌다는 검증 전에는 APK가 정상 연동된다고 보고하지 않는다.

관련 실행 세션은 모두 완료했다. Android 휴대폰은 현재 연결되지 않았다.
