# 스펙모아.zip 휴대폰 실행 가이드

Flutter 앱을 실제 Android 휴대폰에서 실행할 때는 앱이 PC의 NestJS 서버 주소를 바라보도록 실행해야 합니다.

## 1. PC와 휴대폰을 같은 네트워크에 연결

PC와 휴대폰이 같은 Wi-Fi에 연결되어 있어야 합니다.

## 2. PC의 IPv4 주소 확인

PowerShell에서 실행합니다.

```powershell
ipconfig
```

`무선 LAN 어댑터 Wi-Fi` 또는 현재 사용 중인 네트워크의 `IPv4 주소`를 확인합니다.

예:

```text
IPv4 주소 . . . . . . . . . : 192.168.0.15
```

## 3. 서버 실행

```powershell
cd C:\app_project\server
npm run start:dev
```

서버는 기본적으로 `3000` 포트를 사용합니다.

## 4. Flutter 앱을 휴대폰으로 실행

`192.168.0.15` 부분은 본인 PC의 IPv4 주소로 바꿉니다.

```powershell
cd C:\app_project\ui
flutter run --dart-define=API_BASE_URL=http://192.168.0.15:3000
```

## 5. 연결이 안 될 때 확인할 것

- 휴대폰과 PC가 같은 Wi-Fi인지 확인합니다.
- Windows 방화벽에서 Node.js 또는 3000 포트 접근을 허용합니다.
- 서버 터미널에 NestJS가 정상 실행 중인지 확인합니다.
- 앱을 hot reload가 아니라 완전히 재실행합니다.

## 참고

Android 실제 기기에서 로컬 HTTP 서버에 접속할 수 있도록 `ui/android/app/src/main/AndroidManifest.xml`에 인터넷 권한과 개발용 HTTP 접속 허용을 추가했습니다.
