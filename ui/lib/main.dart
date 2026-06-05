import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'auth/auth_session.dart';
import 'screens/auth_gate.dart';
import 'settings/app_settings.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(SpecMoaApp());
}

class SpecMoaApp extends StatelessWidget {
  SpecMoaApp({super.key});

  final AuthSession _session = AuthSession();
  final AppSettingsController _settings = AppSettingsController()..load();

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
