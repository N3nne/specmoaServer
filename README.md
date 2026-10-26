# 스펙모아.zip

자격증 중심 관리에서 학력·어학·프로젝트·경력 등 전체 스펙 관리로 확장 중인 Android 프로토타입입니다.

## 프로젝트 구성

```text
ui/       Flutter 앱: 내 스펙 / 타이머 / 탐색 / 마이
server/   NestJS API, TypeORM, PostgreSQL
docs/     요구사항, 디자인, API 계약, 배포 및 검증 기록
```

서버는 Render, 데이터베이스는 Supabase PostgreSQL을 사용합니다. 앱은 HTTPS API로 서버에 연결하며 DB 비밀번호와 외부 API 키를 포함하지 않습니다.

## 업데이트 기록

### v0.2.1 (Android 빌드 5)

- 하단 내비게이션 영역을 본문과 분리해 내 스펙의 마지막 카드가 메뉴 뒤로 가려지던 문제 수정.
- 스크롤할 때 본문이 상단 바 아래로 비치던 현상을 없애고 상단 바 위치 고정.
- 내 스펙 / 타이머 / 탐색 / 마이의 상단 바를 공통 컴포넌트로 통일.
- Stitch B안 기준 높이 56, 좌우 여백 20, 아이콘 20, 등록된 SpecJakarta / SpecInter 글꼴 적용.
- 각 탭의 알림·설정 아이콘 위치와 동작 통일. 실제 상태 확인 없이 고정 표시되던 실시간 연동 문구 제거.
- 작은 화면·확대 글자·시스템 하단 여백·마지막 카드 스크롤 회귀 테스트 추가.
- 앱 화면만 수정했으며 서버 API와 Supabase 스키마는 변경하지 않음. 서버 패키지 버전은 0.2.0 유지.

[v0.2.1 프로토타입 릴리스](https://github.com/N3nne/specmoaServer/releases/tag/v0.2.1-prototype)

### v0.2.0 (Android 빌드 4)

- 사용자별 8종 스펙 등록·수정·삭제, 로그인 세션과 계정별 데이터 분리.
- 자유 학습 및 등록 스펙 연결 타이머, 학습 기록 저장.
- 가상 채용공고 조회와 규칙 기반 조건 비교. 개인화 AI는 아직 활성화하지 않음.
- Supabase 백업·복원 검증 후 테이블 추가, Render 배포 및 실제 API 41개 검증.

[v0.2.0 프로토타입 릴리스](https://github.com/N3nne/specmoaServer/releases/tag/v0.2.0-prototype)

### 기존 버전

0.1.x 자격증 중심 프로토타입과 기존 릴리스는 보존합니다. 현재 배포 파일은 Android APK이며 iOS 배포 파일은 제공하지 않습니다.

## 실행

Flutter 앱을 배포 서버에 연결:

```powershell
cd ui
flutter pub get
flutter run --dart-define=API_BASE_URL=https://specmoa-api.onrender.com
```

NestJS 서버를 로컬에서 실행:

```powershell
cd server
npm ci --include=dev
Copy-Item .env.example .env
# .env에 로컬 DB와 인증 설정을 입력한 뒤 실행
npm run start:dev
```

API는 Bearer 토큰과 서버 세션으로 사용자를 확인합니다. 이전 버전의 `x-user-id` 데모 인증 방식은 사용하지 않습니다.

## 변경 기록 원칙

앞으로 코드 수정은 관련 테스트 결과와 변경 설명을 함께 GitHub 커밋으로 기록합니다. APK를 배포하는 변경은 앱 버전·빌드 번호를 올리고 README와 릴리스 설명을 갱신합니다. 현재 작업 브랜치는 `specmoa_ver2(0.2.0)`이며 `main` 반영은 Render 자동 배포를 유발하므로 별도 승인 없이 변경하지 않습니다.

`.env`, 비밀번호·토큰, DB 백업, 서명 키, `node_modules`, 빌드 폴더는 커밋하지 않습니다. APK와 체크섬은 소스가 아닌 GitHub Releases에 저장합니다.

## 테스트 버전 주의

공고는 가상 데이터이며 실제 지원 공고가 아닙니다. 실제 사용자 정보를 외부 AI로 전송하지 않습니다. 런타임 의존성 보안 경고와 로그인 요청 제한 등 정식 운영 전 보완 항목이 남아 있으므로 중요한 개인정보 입력은 피해주세요.
