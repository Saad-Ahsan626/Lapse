import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/app/providers/theme_mode_provider.dart';
import 'package:lapse/core/providers/storage_providers.dart';
import 'package:lapse/features/settings/domain/entities/app_theme_mode.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../helpers/in_memory_settings_repository.dart';

void main() {
  test('theme changes are saved and mapped to Material', () async {
    final repository = InMemorySettingsRepository();
    final container = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.system);

    await container
        .read(settingsProvider.notifier)
        .setThemeMode(AppThemeMode.dark);
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(repository.load().themeMode, AppThemeMode.dark);

    await container
        .read(settingsProvider.notifier)
        .setThemeMode(AppThemeMode.light);
    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(repository.saveCount, 2);
  });

  test('an update that changes nothing is not saved', () async {
    final repository = InMemorySettingsRepository();
    final container = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(settingsProvider.notifier).update((s) => s);

    expect(repository.saveCount, 0);
  });

  test('the real repository uses the device country for currency', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final preferences = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        deviceCountryProvider.overrideWithValue('PK'),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(settingsProvider).defaultCurrency, 'PKR');
  });
}
