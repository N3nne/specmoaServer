import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const primary = Color(0xFF0059B9);
  static const primaryContainer = Color(0xFF1071E5);
  static const brandBlue = Color(0xFF3182F6);
  static const secondary = Color(0xFF545F6E);
  static const secondaryContainer = Color(0xFFD5E0F3);
  static const tertiary = Color(0xFF944600);
  static const tertiaryContainer = Color(0xFFBA5900);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);

  static const background = Color(0xFFF8F9FB);
  static const surface = Color(0xFFF8F9FB);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF2F4F6);
  static const surfaceContainer = Color(0xFFECEEF0);
  static const surfaceHigh = Color(0xFFE6E8EA);
  static const surfaceHighest = Color(0xFFE0E3E5);
  static const surfaceDim = Color(0xFFD8DADC);

  static const onSurface = Color(0xFF191C1E);
  static const onSurfaceVariant = Color(0xFF414754);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onSecondaryContainer = Color(0xFF586373);
  static const outline = Color(0xFF727785);
  static const outlineVariant = Color(0xFFC1C6D6);
}

class AppSpacing {
  const AppSpacing._();

  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;
}

class AppRadius {
  const AppRadius._();

  static const double xs = 6;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double full = 999;
}

class AppShadows {
  const AppShadows._();

  static List<BoxShadow> get soft => [
        BoxShadow(
          color: AppColors.onSurface.withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get floating => [
        BoxShadow(
          color: AppColors.onSurface.withValues(alpha: 0.08),
          blurRadius: 40,
          offset: const Offset(0, 16),
        ),
      ];

  static List<BoxShadow> get blueTint => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.06),
          blurRadius: 40,
          offset: const Offset(0, 16),
        ),
      ];
}

class AppTheme {
  const AppTheme._();

  static ThemeData light({bool highContrast = false}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandBlue,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      secondary: AppColors.secondary,
      secondaryContainer: AppColors.secondaryContainer,
      tertiary: AppColors.tertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      error: AppColors.error,
      errorContainer: AppColors.errorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      outline: highContrast ? AppColors.onSurfaceVariant : AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
    );

    return _baseTheme(colorScheme, highContrast: highContrast);
  }

  static ThemeData dark({bool highContrast = false}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandBlue,
      brightness: Brightness.dark,
      primary: const Color(0xFF8FC4FF),
      onPrimary: const Color(0xFF00325F),
      primaryContainer: const Color(0xFF0059B9),
      secondary: const Color(0xFFBAC7DA),
      secondaryContainer: const Color(0xFF3F4A5A),
      tertiary: const Color(0xFFFFB77D),
      tertiaryContainer: const Color(0xFF8E3F00),
      error: const Color(0xFFFFB4AB),
      errorContainer: const Color(0xFF93000A),
      surface: const Color(0xFF111417),
      onSurface: const Color(0xFFE4E7EB),
      outline: highContrast ? const Color(0xFFE4E7EB) : const Color(0xFF8B929D),
      outlineVariant: const Color(0xFF444B55),
    );

    return _baseTheme(
      colorScheme,
      highContrast: highContrast,
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      cardColor: const Color(0xFF171B21),
      inputFillColor: const Color(0xFF202630),
    );
  }

  static ThemeData _baseTheme(
    ColorScheme colorScheme, {
    required bool highContrast,
    Color? scaffoldBackgroundColor,
    Color? cardColor,
    Color? inputFillColor,
  }) {
    final surface = scaffoldBackgroundColor ?? AppColors.background;
    final card = cardColor ?? AppColors.surfaceLowest;
    final inputFill = inputFillColor ?? AppColors.surfaceLow;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      fontFamily: 'Inter',
      fontFamilyFallback: const [
        'Noto Sans KR',
        'Apple SD Gothic Neo',
        'Malgun Gothic',
        'Roboto',
      ],
      textTheme: _textTheme().apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(
            color:
                colorScheme.primary.withValues(alpha: highContrast ? 0.5 : 0.2),
            width: highContrast ? 2.5 : 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: surface.withValues(alpha: 0.92),
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  static TextTheme _textTheme() {
    const displayFamily = 'Plus Jakarta Sans';
    const bodyFamily = 'Inter';

    return const TextTheme(
      displayLarge: TextStyle(
        fontFamily: displayFamily,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 44 / 36,
        letterSpacing: -0.4,
      ),
      headlineLarge: TextStyle(
        fontFamily: displayFamily,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 38 / 30,
        letterSpacing: -0.2,
      ),
      headlineMedium: TextStyle(
        fontFamily: displayFamily,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 34 / 26,
      ),
      headlineSmall: TextStyle(
        fontFamily: displayFamily,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 30 / 22,
      ),
      titleLarge: TextStyle(
        fontFamily: displayFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 28 / 20,
      ),
      titleMedium: TextStyle(
        fontFamily: displayFamily,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 26 / 18,
      ),
      titleSmall: TextStyle(
        fontFamily: displayFamily,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 24 / 16,
      ),
      bodyLarge: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 26 / 16,
      ),
      bodyMedium: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 22 / 14,
      ),
      bodySmall: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 20 / 13,
      ),
      labelLarge: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 20 / 14,
      ),
      labelMedium: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 18 / 12,
      ),
      labelSmall: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 16 / 11,
      ),
    );
  }
}
