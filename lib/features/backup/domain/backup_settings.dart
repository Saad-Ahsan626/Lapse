import 'package:flutter/foundation.dart';

import 'package:lapse/features/settings/domain/entities/app_settings.dart';
import 'package:lapse/features/settings/domain/entities/app_theme_mode.dart';

@immutable
class BackupSettings {
  BackupSettings({
    required this.defaultCurrency,
    required this.reminderMinutes,
    required List<int> defaultReminderOffsets,
    required this.themeMode,
    this.userName,
  }) : defaultReminderOffsets = List.unmodifiable(defaultReminderOffsets);

  factory BackupSettings.of(AppSettings settings) => BackupSettings(
    defaultCurrency: settings.defaultCurrency,
    reminderMinutes: settings.reminderMinutes,
    defaultReminderOffsets: settings.defaultReminderOffsets,
    themeMode: settings.themeMode,
    userName: settings.userName,
  );

  final String defaultCurrency;
  final int reminderMinutes;
  final List<int> defaultReminderOffsets;
  final AppThemeMode themeMode;
  final String? userName;

  AppSettings applyTo(AppSettings current) => current.copyWith(
    defaultCurrency: defaultCurrency,
    reminderMinutes: reminderMinutes,
    defaultReminderOffsets: defaultReminderOffsets,
    themeMode: themeMode,
    userName: userName,
    onboardingDone: true,
  );

  @override
  bool operator ==(Object other) =>
      other is BackupSettings &&
      other.defaultCurrency == defaultCurrency &&
      other.reminderMinutes == reminderMinutes &&
      listEquals(other.defaultReminderOffsets, defaultReminderOffsets) &&
      other.themeMode == themeMode &&
      other.userName == userName;

  @override
  int get hashCode => Object.hash(
    defaultCurrency,
    reminderMinutes,
    Object.hashAll(defaultReminderOffsets),
    themeMode,
    userName,
  );

  @override
  String toString() =>
      'BackupSettings($defaultCurrency, $defaultReminderOffsets at '
      '$reminderMinutes min, ${themeMode.name})';
}
