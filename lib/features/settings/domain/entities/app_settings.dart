import 'package:flutter/foundation.dart';

import 'package:lapse/features/settings/domain/entities/app_theme_mode.dart';

const Object _unset = Object();

@immutable
class AppSettings {
  AppSettings({
    required this.defaultCurrency,
    this.themeMode = AppThemeMode.system,
    this.onboardingDone = false,
    this.userName,
    this.reminderMinutes = defaultReminderMinutes,
    List<int> defaultReminderOffsets = standardReminderOffsets,
  }) : defaultReminderOffsets = List.unmodifiable(defaultReminderOffsets);

  static const int defaultReminderMinutes = 9 * 60;
  static const standardReminderOffsets = [7, 1];

  final AppThemeMode themeMode;
  final bool onboardingDone;
  final String? userName;
  final String defaultCurrency;
  final int reminderMinutes;
  final List<int> defaultReminderOffsets;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? onboardingDone,
    Object? userName = _unset,
    String? defaultCurrency,
    int? reminderMinutes,
    List<int>? defaultReminderOffsets,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    userName: identical(userName, _unset) ? this.userName : userName as String?,
    defaultCurrency: defaultCurrency ?? this.defaultCurrency,
    reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    defaultReminderOffsets:
        defaultReminderOffsets ?? this.defaultReminderOffsets,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.themeMode == themeMode &&
      other.onboardingDone == onboardingDone &&
      other.userName == userName &&
      other.defaultCurrency == defaultCurrency &&
      other.reminderMinutes == reminderMinutes &&
      listEquals(other.defaultReminderOffsets, defaultReminderOffsets);

  @override
  int get hashCode => Object.hash(
    themeMode,
    onboardingDone,
    userName,
    defaultCurrency,
    reminderMinutes,
    Object.hashAll(defaultReminderOffsets),
  );

  @override
  String toString() =>
      'AppSettings(${themeMode.name}, $defaultCurrency, '
      'reminders $defaultReminderOffsets at $reminderMinutes min, '
      'onboarding ${onboardingDone ? 'done' : 'pending'})';
}
