# 개발 이어하기 기록

최종 갱신: 2026-10-27, Asia/Seoul

## 현재 요청

2026-10-27 추가 요청: 모바일 내 스펙 카드 잘림과 메인 앱 바 불일치를 수정하고 v0.2.1 APK 설치·GitHub 릴리스·README 업데이트를 진행한다. 이후 수정도 GitHub에 기록한다. 현재 진행/검증은 `docs/prototype_release_v0.2.1.md`를 먼저 확인한다. 이번 변경은 앱만이며 main/Render/DB는 그대로 유지한다.

v0.2.1+5의 카드 하단 가림 수정과 MainTabHeader 공통화를 완료했다. Flutter 130개 테스트·정적 분석·릴리스 빌드 통과, S24 업데이트 설치 및 기존 로그인 복구/스크롤 화면 확인 완료. README를 최신 기능과 버전별 변경 기록으로 갱신했다. 소스 bb8ddf5와 APK·체크섬을 GitHub v0.2.1-prototype 릴리스(ID 424844880)로 공개했고, 공개 다운로드 200 및 휴대폰 설치본/업로드 APK 해시 일치를 확인했다. 자세한 결과는 v0.2.1 배포 기록을 따른다. 이후 수정도 관련 테스트와 함께 GitHub에 기록한다.

추가 요청: 현재 앱을 테스트용 APK로 만들고 GitHub에 다음 버전으로 저장한다.
버전 브랜치는 사용자 요청으로 `codex/prototype-v0.2.0`에서 `specmoa_ver2(0.2.0)`으로 변경했다. 로컬도 같은 브랜치를 사용한다. 앱 `0.2.0+4`, 서버 `0.2.0`이며 Render의 main 브랜치는 유지한다.
사용자는 기존 Supabase 백업 후 테이블 추가 방식을 승인했다. 백업 검증 전에는 클라우드를 변경하지 않는다.
현재 배포 작업의 진행 상황은 `docs/prototype_release_v0.2.0.md`를 먼저 읽는다.
APK 빌드·GitHub 버전 브랜치 푸시·APK 초안 릴리즈 저장까지 완료했다. 사용자가 비밀번호를 수정해 Supabase 접속과 public 스키마 백업·로컬 복원 검증·마이그레이션 3개·가상 공고 40건 저장을 완료했다.
기존 19개 테이블의 모든 기존 필드 내용 보존을 확인했다. 이후 사용자 승인으로 main을 fast-forward 반영했고 Render 배포와 실제 API 검증 41개를 완료했다.
백업 경로와 체크섬, 검증 메타데이터는 배포 기록과 로컬 `.buildlog/supabase-backup-state.json`에 있다. 클라우드 연결을 닫고 로컬 임시 복원 DB를 정리했으며 백업은 보존했다.
브라우저 제어는 중단했지만 2026-10-27 사용자가 Render 연동을 연결해 정상 API 접근이 가능해졌다. 워크스페이스 nne's workspace와 기존 무료 specmoa-api를 확인했다.
사용자가 v0.2.0의 main 반영 및 자동 배포를 명시적으로 승인했다. 유효한 DB 접속과 필수 환경변수를 병합 반영했고 Render 배포 dep-dbfnvnmdjanc73aetnng가 live다. 실행 커밋은 f49958c, 기존 무료 요금제/서버 주소를 유지했다.
실제 API 검증에 쓴 임시 계정 2개와 연결 데이터를 모두 정리했으며 기존 19개 테이블의 기존 필드 내용 보존을 재확인했다. 원격 연결은 닫았다.
사용자의 USB 디버깅 허용 후 S24에 기존 0.1.2 데이터를 지우지 않고 0.2.0(빌드 4)을 업데이트 설치했다. 로그인 화면 표시, 앱 프로세스 유지, 시작 구간 Android/Flutter 오류 로그 0건을 확인했다. 로그인 이후 전체 기능의 실기기 검증은 아직 별도 진행이 필요하다.
사용자가 프로토타입 공개를 승인해 APK와 체크섬 릴리스를 공개했다: https://github.com/N3nne/specmoaServer/releases/tag/v0.2.0-prototype . GitHub 인증 없이 릴리스와 APK 다운로드 모두 HTTP 200을 확인했다. QR 생성은 이번 요청에 포함되지 않았다. 런타임 의존성 보안 경고(높음 4, 보통 7)는 정식 운영 전 별도 보완이 필요하다.

사용자 요청: 다음 작업을 진행하고, 사용량이 부족해 중단되더라도 이어갈 수 있도록 준비한다.
예약 실행이나 자동 재개 요청은 아니다. 이 문서를 다음 대화의 시작점으로 사용한다.

## 지켜야 할 결정

- 앱은 내 스펙 / 타이머 / 탐색 / 마이 4개 탭이다. 상세 필터·스크랩을 다시 추가하지 않는다.
- 스펙 8종 입력은 전부 선택 항목이다. 준비 중 자격증/어학은 제외, 진행 중 활동·재직·재학은 유지한다.
- 새로운 UI는 임의 생성하지 않는다. Stitch `specmoa.zip_ui_2` 원본을 확인하고 정확히 구현한다.
- 희망 직무 입력 UI는 사용자가 나중에 제공하기로 했다. 지금은 화면을 만들거나 다른 화면에 끼워 넣지 않는다.
- 실제 사용자 정보를 Gemini로 보내지 않는다. 현재 AI는 고정 가상 프로필 시연이며 개인화 추천은 별도 승인/데이터 처리 정책이 필요하다.
- 기존 작업이 많이 남아 있는 dirty worktree다. 다른 변경을 되돌리지 않는다. 2026-10-27 사용자가 앱/서버 소스의 새 버전 GitHub 저장을 승인했으며, 다른 프로젝트·비밀정보·산출물은 커밋하지 않는다. main 푸시/공개 릴리즈는 호환성 검증과 별도 판단이 필요하다.
- `.env`·토큰·비밀번호·실제 사용자 분석 원문을 출력/문서화하지 않는다.

## 직전 완료

- 서버 `src/career`에 희망 직무 저장/조회, 직무 목록, 사용자별 8종 스펙 분석용 정리 API 구현.
- 기존 `user_profiles.preferences.career` 사용, 새 마이그레이션 없음.
- 사용자 소유권 검증, 다른 설정 보존, 동시 저장, 원본 추적, 수정/삭제 반영, 외부 AI 호출 없음 검증.
- 서버 빌드 및 격리 PostgreSQL을 포함한 테스트 62개 통과.
- 자세한 계약: `docs/career_analysis_preparation.md`.

## 이번 작업 체크리스트

- [x] 기존 서버 계약·Flutter 인증 클라이언트·모델 패턴 확인.
- [x] Flutter용 희망 직무/분석 데이터 모델 작성 및 응답 일관성 검증.
- [x] 기존 `AuthenticatedClient`를 재사용하는 Career API 클라이언트 작성.
- [x] 모델·통신·계정 변경·인증 갱신·오류 처리 테스트. 새 테스트 13개 통과.
- [x] 실제 서버가 생성한 가상 데이터로 서버/Flutter 계약 교차 검증.
- [x] 전체 회귀 테스트·정적 분석 후 이 문서에 결과와 남은 작업 기록.

## 다음 재개 시

1. 이 문서와 `docs/career_analysis_preparation.md`를 읽고 `git status --short`로 현재 변경을 확인한다.
2. 이번 체크리스트는 완료했다. 아래 '다음 실제 작업'을 확인한다. 파일이 이미 있다면 읽고 이어서 수정한다.
3. 서버 테스트는 `C:\app_project\server`에서 `npm run build`, `RUN_DB_TESTS=true npm test`.
4. Flutter는 `C:\dev\flutter\bin\flutter.bat`를 사용한다. 기존 의존성으로 `flutter test --no-pub`, `flutter analyze --no-pub`.
5. DB 테스트는 반드시 localhost의 무작위 이름 격리 DB만 사용하고 종료 후 해당 DB만 정리한다. Supabase를 테스트 대상으로 쓰지 않는다.

## 아직 하지 않는 작업

- 희망 직무 입력 화면 및 앱 화면 연결: Stitch 원본 대기.
- 실제 개인화 AI 활성화: 데이터 전송 범위·고지/동의·보관/삭제 정책 확정 후 별도 진행.
- Render / Supabase / GitHub 배포, 새 APK, 예약 자동 재개.

이번 작업은 완료했다. 미완료 코드/필수 실행 중인 테스트 세션은 없다.

작업 중 추가한 파일:

- `ui/lib/models/career_data.dart`: 직무/설정/분석 데이터의 불변 모델, 버전·출처·집계·개인정보 처리 경계 검증.
- `ui/lib/services/career_api_client.dart`: 기존 인증·갱신·계정 변경 차단 재사용, 오류 메시지 고정, 응답 캐시/영구 저장 없음.
- `ui/test/career_api_test.dart`, `ui/test/fixtures/career_fixture.dart`: 가상 응답 테스트.
- `ui/tool/check_career_contract.dart`: 실제 서버 가상 응답을 Dart 모델로 교차 검사.
- 서버 PostgreSQL 테스트에 선택적 `EXPORT_CAREER_CONTRACT=true` 가상 응답 출력 추가. 고정 출력 위치는 `.buildlog/career-contract.json`이며 토큰/비밀번호는 포함하지 않는다.
- 서버의 저장된 설정 시각을 정규 UTC ISO 형식으로 확인하도록 보강. 이상한 이전 설정은 추측하지 않고 `needs_review`로 반환한다.

## 검증 결과

- 서버 `npm run build`: 통과.
- 격리 PostgreSQL 테스트를 포함한 서버 62개 테스트 통과, 건너뜀 없음.
- Flutter `flutter test --no-pub`: 전체 120개 통과. 이번에 추가한 Career 테스트는 13개다.
- Flutter `flutter analyze --no-pub`: 문제 없음.
- 실제 Nest HTTP 응답의 10개 직무와 8종 스펙을 Dart 모델로 파싱하는 교차 검사 통과.
- 교차 검사에서 원본 경로, 수정 본문, 삭제 반영, 빈 초기 상태, 외부 AI 전송 불가 상태도 확인.
- 실제 사용자 원문·계정·토큰은 교차 검사 파일에 넣지 않았다. 검사는 격리 테스트 계정만 사용하고 테스트 DB를 정리했다.
- 기존 화면, AI 시연, Supabase/Render/GitHub/APK는 변경하지 않았다. 새 API 클라이언트는 아직 화면에 연결되지 않는다.

교차 검사 재실행(두 번째 명령은 서버 테스트 성공을 확인한 후 실행):

```powershell
# C:\app_project\server
$env:RUN_DB_TESTS='true'
$env:EXPORT_CAREER_CONTRACT='true'
node --test -r ts-node/register test/postgres-career.test.ts
```

```powershell
# C:\app_project\ui
C:\dev\flutter\bin\dart.bat run tool/check_career_contract.dart C:\app_project\.buildlog\career-contract.json
```

## 다음 실제 작업

1. 사용자가 희망 직무 입력/수정 Stitch 원본을 제공하면 screenshot·HTML·assets·수치를 확인한다. 그 전에는 화면을 임의로 추가하지 않는다.
2. 원본 UI에 `CareerApiClient.fetchOccupations/fetchPreferences/updatePreferences`를 연결한다. 초기 선택을 강제하지 않고 빈 배열 해제를 지원한다.
3. `fetchAnalysisContext`로 부족 정보를 보여줄 별도 화면/영역도 원본 또는 승인 후 연결한다. `available`을 합격률/지원 자격 충족으로 표시하지 않는다.
4. 실제 개인화 AI는 외부 전송 범위·정책 결정 이후 별도 구현한다. 현재 가상 AI 시연 입력을 실제 사용자 스펙으로 바꾸면 안 된다.
5. 원본 대기 중 진행 가능한 별도 후보는 로그인 요청 제한·비밀번호 재설정 메일 등이다. 이 작업의 일부로 자동 착수하지 않았다.
