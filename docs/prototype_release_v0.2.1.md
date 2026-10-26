# v0.2.1 모바일 화면 수정

작업일: 2026-10-27, Asia/Seoul

## 요청 및 범위

- 내 스펙 화면 스크롤 시 하단 카드 잘림 수정.
- 네 개 메인 탭의 앱 바 폰트·아이콘·위치 통일.
- Android v0.2.1 APK 설치, GitHub 릴리스와 README에 수정 기록.
- 이후 변경도 관련 코드·검증·README·릴리스로 GitHub에 기록한다. 비밀정보와 APK는 소스 커밋에서 제외한다.
- 작업 브랜치 `specmoa_ver2(0.2.0)`은 유지한다. 이번 변경은 클라이언트만이며 main/Render/DB는 수정하지 않는다.

## Stitch 확인 및 구현

- 프로젝트 `7372440937946396208`, 원본 `a8cea2349b8143dfb48f9bcbb6c9ab16` (내 스펙 Variant B)의 screenshot과 HTML을 MCP로 확인했다.
- 상단 기준: 높이 56, 좌우 padding 20, 브랜드 17/800 및 .zip 12/500, 섹션 칩 11/600, 아이콘 20 및 버튼 36, 아이콘 간격 2.
- 원본 primary #0057BD, secondary #3A53B7, surface #F5F7F9, on-surface-variant #595C5E 사용. 다크 테마에서는 기존 colorScheme 대응 색상을 사용한다.
- 등록된 SpecJakarta / SpecInter 폰트 파일을 재사용한다. 상단 원본에는 별도 이미지가 없어 새 이미지 자산은 만들지 않았다.
- 원본과 의도적으로 다른 점: 네 탭 공통화, 실제 상태를 보장하지 않는 실시간 연동 칩 제거, 본문이 비치지 않는 불투명 헤더, 글자 확대/좁은 화면에서 섹션 칩 숨김.

## 변경 내용

- RootShell이 SafeArea와 고정 MainTabHeader를 한 번만 관리한다. 화면별 중복 헤더를 제거했다.
- extendBody를 사용하지 않아 하단 내비게이션과 시스템 하단 여백을 실제 레이아웃에서 확보한다. 임의의 큰 하단 보정값 대신 본문 하단 24 여백을 둔다.
- 알림/설정 아이콘은 모든 메인 탭에서 같은 크기·좌표로 동작하며 기존 설정 화면으로 이동한다.
- 내 스펙 요약/섹션 제목은 공간이 부족할 때 줄바꿈해 가로 잘림을 방지한다. 스펙 입력·저장·삭제 로직은 유지한다.
- 테스트용 UserSpecApiClient 주입 지점을 기존 클라이언트 패턴대로 추가했다. 실제 실행의 기본 클라이언트는 동일하다.
- 앱 버전 `0.2.1+5`, 서버 버전은 변경 없음(`0.2.0`).

## 검증

- [x] 새 레이아웃 테스트 10개 통과: 폭 320/360/390/520, 글자 배율 1/1.5, 탭별 아이콘 고정, 시스템 하단 48 여백, 스펙 12개 중 마지막 카드 전체 노출.
- [x] Flutter 전체 테스트 130개 통과.
- [x] Flutter analyze 오류 없음.
- [x] Release APK 빌드·서명·버전·서버 주소 확인.
- [x] S24 업데이트 설치 및 스크롤/탭별 실제 화면 확인.
- [ ] GitHub 소스 push, APK·체크섬 릴리스 업로드·공개 다운로드 확인.

APK: `release/specmoa-prototype-v0.2.1.apk`, 56,215,966 bytes.
SHA-256: `f68bf9aa43a133b2f8299208320ab8007d62e49ce69e976c646638b68fdf42eb`.
동일한 Android Debug 테스트 서명으로 기존 설치를 유지한 채 업데이트했다. 패키지 `com.example.specmoa_zip_ui`, 버전 `0.2.1`, 빌드 `5`, API 24 이상, Render HTTPS 주소 포함·localhost API 주소 미포함을 확인했다.

S24의 기존 로그인 세션이 복구됐고 내 스펙 마지막 빈 상태 카드가 하단 메뉴 위로 전체 표시되는 것을 실제 screenshot으로 확인했다. 12개 스펙 카드가 있는 경우는 가상 데이터 위젯 테스트로 별도 검증했다. 네 탭의 공통 상단 바와 탐색 목록 표시를 확인했으며, 최종 실행 로그의 Android/Flutter 오류는 0건이었다. 새 스펙이나 학습 기록을 실제 사용자 계정에 추가하지 않았다.

로컬 화면 증빙은 `.buildlog/device-v0.2.1-*.png`이다. 사용자 계정 정보가 포함될 수 있어 GitHub에 올리지 않는다.

## 재사용 및 신규 컴포넌트

- 재사용: ResponsivePage, 기존 NavigationBar, NotificationSettingsScreen, SettingsHubScreen, 내 스펙 카드 및 타이머/탐색/마이 본문.
- 신규: MainTabHeader, 내부 HeaderButton, main_tab_layout_test.dart.
- 수정 파일: ui/lib/screens/root_shell.dart, my_spec_screen.dart, profile_screen.dart, explore_screen.dart, timer_screen.dart, ui/lib/widgets/main_tab_header.dart, ui/test/main_tab_layout_test.dart, ui/pubspec.yaml, README.md, 배포 및 이어하기 문서.

## 남은 범위

서버 의존성 보안 경고·로그인 요청 제한·개인화 AI 등 기존 미완료 범위는 이번 UI 수정에 포함하지 않는다. 새로운 UI를 임의 생성하지 않았으며 등록/상세 화면의 본문 디자인도 바꾸지 않았다.
