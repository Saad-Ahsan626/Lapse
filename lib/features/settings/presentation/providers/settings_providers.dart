import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/core/domain/currency_for_country.dart';
import 'package:lapse/core/providers/storage_providers.dart';
import 'package:lapse/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:lapse/features/settings/domain/entities/app_settings.dart';
import 'package:lapse/features/settings/domain/entities/app_theme_mode.dart';
import 'package:lapse/features/settings/domain/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(
    ref.watch(sharedPreferencesProvider),
    fallbackCurrency: currencyForCountry(ref.watch(deviceCountryProvider)),
  ),
);

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> update(AppSettings Function(AppSettings current) change) async {
    final next = change(state);
    if (next == state) return;
    state = next;
    await ref.read(settingsRepositoryProvider).save(next);
  }

  Future<void> setThemeMode(AppThemeMode mode) =>
      update((settings) => settings.copyWith(themeMode: mode));
}
