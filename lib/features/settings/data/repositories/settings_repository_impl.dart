import 'package:lapse/features/settings/domain/entities/app_settings.dart';
import 'package:lapse/features/settings/domain/entities/app_theme_mode.dart';
import 'package:lapse/features/settings/domain/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(
    this._preferences, {
    required String fallbackCurrency,
  }) : _fallbackCurrency = fallbackCurrency;

  final SharedPreferencesWithCache _preferences;
  final String _fallbackCurrency;

  static const _themeMode = 'lapse.themeMode';
  static const _onboardingDone = 'lapse.onboardingDone';
  static const _userName = 'lapse.userName';
  static const _defaultCurrency = 'lapse.defaultCurrency';
  static const _reminderMinutes = 'lapse.reminderMinutes';
  static const _defaultReminderOffsets = 'lapse.defaultReminderOffsets';

  static const Set<String> allKeys = {
    _themeMode,
    _onboardingDone,
    _userName,
    _defaultCurrency,
    _reminderMinutes,
    _defaultReminderOffsets,
  };

  @override
  AppSettings load() {
    final minutes = _read(() => _preferences.getInt(_reminderMinutes));
    final offsets = _read(
      () => _preferences
          .getStringList(_defaultReminderOffsets)
          ?.map(int.parse)
          .toList(),
    );
    return AppSettings(
      themeMode:
          AppThemeMode.fromStorage(
            _read(() => _preferences.getString(_themeMode)),
          ) ??
          AppThemeMode.system,
      onboardingDone:
          _read(() => _preferences.getBool(_onboardingDone)) ?? false,
      userName: _read(() => _preferences.getString(_userName)),
      defaultCurrency:
          _read(() => _preferences.getString(_defaultCurrency)) ??
          _fallbackCurrency,
      reminderMinutes: minutes != null && minutes >= 0 && minutes < 24 * 60
          ? minutes
          : AppSettings.defaultReminderMinutes,
      defaultReminderOffsets: offsets ?? AppSettings.standardReminderOffsets,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _preferences.setString(_themeMode, settings.themeMode.name);
    await _preferences.setBool(_onboardingDone, settings.onboardingDone);
    final name = settings.userName;
    if (name == null) {
      await _preferences.remove(_userName);
    } else {
      await _preferences.setString(_userName, name);
    }
    await _preferences.setString(_defaultCurrency, settings.defaultCurrency);
    await _preferences.setInt(_reminderMinutes, settings.reminderMinutes);
    await _preferences.setStringList(
      _defaultReminderOffsets,
      settings.defaultReminderOffsets.map((d) => '$d').toList(),
    );
  }

  T? _read<T>(T? Function() read) {
    try {
      return read();
    } on Object {
      return null;
    }
  }
}
