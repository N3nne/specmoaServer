import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:specmoa_zip_ui/models/user_spec.dart';
import 'package:specmoa_zip_ui/screens/specs/spec_register_screen.dart';
import 'package:specmoa_zip_ui/screens/specs/spec_type_selection_screen.dart';
import 'package:specmoa_zip_ui/theme/app_theme.dart';

// Read-only visual QA entry point; normal application builds still use lib/main.dart.
void main() {
  final value = Uri.base.queryParameters['type'] ?? 'certification';
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: '/',
    locale: const Locale('ko'),
    supportedLocales: const [Locale('ko')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ],
    theme: AppTheme.light(),
    home: value == 'selection'
        ? const SpecTypeSelectionScreen()
        : SpecRegisterScreen(type: SpecType.parse(value)),
  ));
}
