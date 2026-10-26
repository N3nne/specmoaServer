import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'auth/auth_session.dart';
import 'screens/auth_gate.dart';
import 'settings/app_settings.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpecMoaApp());
}

class SpecMoaApp extends StatefulWidget {
  const SpecMoaApp({super.key});

  @override
  State<SpecMoaApp> createState() => _SpecMoaAppState();
}

class _SpecMoaAppState extends State<SpecMoaApp> {
  late final AuthSession _session;
  late final AppSettingsController _settings;
  late final Future<void> _settingsReady;

  @override
  void initState() {
    super.initState();
    _session = AuthSession()..restore();
    _settings = AppSettingsController();
    _settingsReady = _settings.load().catchError((Object _) {
      debugPrint('앱 설정을 불러오지 못해 기본값을 사용합니다.');
    });
  }

  @override
  void dispose() {
    _session.dispose();
    unawaited(_settingsReady.then((_) => _settings.dispose()));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      controller: _settings,
      child: AuthScope(
        session: _session,
        child: AnimatedBuilder(
          animation: _settings,
          builder: (context, _) {
            return MaterialApp(
              title: '스펙모아.zip',
              debugShowCheckedModeBanner: false,
              scrollBehavior: const _SpecMoaScrollBehavior(),
              locale: const Locale('ko', 'KR'),
              supportedLocales: const [
                Locale('ko', 'KR'),
                Locale('en', 'US'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              theme: AppTheme.light(highContrast: _settings.highContrast),
              darkTheme: AppTheme.dark(highContrast: _settings.highContrast),
              themeMode: _settings.themeMode,
              builder: (context, child) {
                final mediaQuery = MediaQuery.of(context);
                return MediaQuery(
                  data: mediaQuery.copyWith(
                    textScaler: TextScaler.linear(_settings.textScale),
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
              home: AuthGate(session: _session),
            );
          },
        ),
      ),
    );
  }
}

class _SpecMoaScrollBehavior extends MaterialScrollBehavior {
  const _SpecMoaScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
