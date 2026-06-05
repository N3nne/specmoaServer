import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference {
  system,
  light,
  dark;

  ThemeMode get themeMode {
    switch (this) {
      case AppThemePreference.system:
        return ThemeMode.system;
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
    }
  }
}

class AppSettingsController extends ChangeNotifier {
  static const _themeKey = 'app_settings.theme';
  static const _textScaleKey = 'app_settings.text_scale';
  static const _pushKey = 'app_settings.push';
  static const _studyReminderKey = 'app_settings.study_reminder';
  static const _examScheduleNotificationKey =
      'app_settings.exam_schedule_notification';
  static const _communityNotificationKey =
      'app_settings.community_notification';
  static const _successStoryNotificationKey =
      'app_settings.success_story_notification';
  static const _quietHoursKey = 'app_settings.quiet_hours';
  static const _autoRefreshKey = 'app_settings.auto_refresh';
  static const _marketingKey = 'app_settings.marketing';
  static const _highContrastKey = 'app_settings.high_contrast';

  SharedPreferences? _preferences;

  AppThemePreference _themePreference = AppThemePreference.system;
  double _textScale = 1;
  bool _pushEnabled = true;
  bool _studyReminder = true;
  bool _examScheduleNotification = true;
  bool _communityNotification = true;
  bool _successStoryNotification = false;
  bool _quietHours = false;
  bool _autoRefresh = true;
  bool _marketing = false;
  bool _highContrast = false;

  AppThemePreference get themePreference => _themePreference;
  ThemeMode get themeMode => _themePreference.themeMode;
  double get textScale => _textScale;
  bool get pushEnabled => _pushEnabled;
  bool get studyReminder => _studyReminder;
  bool get examScheduleNotification => _examScheduleNotification;
  bool get communityNotification => _communityNotification;
  bool get successStoryNotification => _successStoryNotification;
  bool get quietHours => _quietHours;
  bool get autoRefresh => _autoRefresh;
  bool get marketing => _marketing;
  bool get highContrast => _highContrast;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _preferences = preferences;

    final themeName = preferences.getString(_themeKey);
    _themePreference = AppThemePreference.values.firstWhere(
      (theme) => theme.name == themeName,
      orElse: () => AppThemePreference.system,
    );
    _textScale = (preferences.getDouble(_textScaleKey) ?? 1).clamp(0.9, 1.2);
    _pushEnabled = preferences.getBool(_pushKey) ?? true;
    _studyReminder = preferences.getBool(_studyReminderKey) ?? true;
    _examScheduleNotification =
        preferences.getBool(_examScheduleNotificationKey) ?? true;
    _communityNotification =
        preferences.getBool(_communityNotificationKey) ?? true;
    _successStoryNotification =
        preferences.getBool(_successStoryNotificationKey) ?? false;
    _quietHours = preferences.getBool(_quietHoursKey) ?? false;
    _autoRefresh = preferences.getBool(_autoRefreshKey) ?? true;
    _marketing = preferences.getBool(_marketingKey) ?? false;
    _highContrast = preferences.getBool(_highContrastKey) ?? false;

    notifyListeners();
  }

  Future<void> setThemePreference(AppThemePreference preference) async {
    if (_themePreference == preference) {
      return;
    }
    _themePreference = preference;
    notifyListeners();
    await _preferences?.setString(_themeKey, preference.name);
  }

  Future<void> setTextScale(double scale) async {
    final nextScale = scale.clamp(0.9, 1.2);
    if (_textScale == nextScale) {
      return;
    }
    _textScale = nextScale;
    notifyListeners();
    await _preferences?.setDouble(_textScaleKey, nextScale);
  }

  Future<void> setPushEnabled(bool value) async {
    _pushEnabled = value;
    notifyListeners();
    await _preferences?.setBool(_pushKey, value);
  }

  Future<void> setStudyReminder(bool value) async {
    _studyReminder = value;
    notifyListeners();
    await _preferences?.setBool(_studyReminderKey, value);
  }

  Future<void> setExamScheduleNotification(bool value) async {
    _examScheduleNotification = value;
    notifyListeners();
    await _preferences?.setBool(_examScheduleNotificationKey, value);
  }

  Future<void> setCommunityNotification(bool value) async {
    _communityNotification = value;
    notifyListeners();
    await _preferences?.setBool(_communityNotificationKey, value);
  }

  Future<void> setSuccessStoryNotification(bool value) async {
    _successStoryNotification = value;
    notifyListeners();
    await _preferences?.setBool(_successStoryNotificationKey, value);
  }

  Future<void> setQuietHours(bool value) async {
    _quietHours = value;
    notifyListeners();
    await _preferences?.setBool(_quietHoursKey, value);
  }

  Future<void> setAutoRefresh(bool value) async {
    _autoRefresh = value;
    notifyListeners();
    await _preferences?.setBool(_autoRefreshKey, value);
  }

  Future<void> setMarketing(bool value) async {
    _marketing = value;
    notifyListeners();
    await _preferences?.setBool(_marketingKey, value);
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    notifyListeners();
    await _preferences?.setBool(_highContrastKey, value);
  }
}

class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    required AppSettingsController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppSettingsController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}
