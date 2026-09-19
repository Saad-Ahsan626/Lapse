import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:lapse/features/settings/domain/entities/app_settings.dart';
import 'package:lapse/features/settings/domain/entities/app_theme_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  Future<SettingsRepositoryImpl> repository({
    Map<String, Object> values = const {},
  }) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData(values);
    final preferences = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: SettingsRepositoryImpl.allKeys,
      ),
    );
    return SettingsRepositoryImpl(preferences, fallbackCurrency: 'PKR');
  }

  test('empty storage gives the defaults', () async {
    final settings = (await repository()).load();

    expect(settings, AppSettings(defaultCurrency: 'PKR'));
    expect(settings.themeMode, AppThemeMode.system);
    expect(settings.reminderMinutes, 9 * 60);
    expect(settings.defaultReminderOffsets, [7, 1]);
    expect(settings.onboardingDone, isFalse);
  });

  test('save then load round trips', () async {
    final repo = await repository();
    final changed = AppSettings(
      defaultCurrency: 'USD',
      themeMode: AppThemeMode.dark,
      onboardingDone: true,
      userName: 'Saad',
      reminderMinutes: 20 * 60 + 30,
      defaultReminderOffsets: const [3, 0],
    );

    await repo.save(changed);

    expect(repo.load(), changed);
  });

  test('clearing the name removes it', () async {
    final repo = await repository();
    await repo.save(AppSettings(defaultCurrency: 'PKR', userName: 'Saad'));

    await repo.save(repo.load().copyWith(userName: null));

    expect(repo.load().userName, isNull);
  });

  test('corrupt values fall back to defaults', () async {
    final settings = (await repository(
      values: {
        'lapse.themeMode': 'purple',
        'lapse.reminderMinutes': 5000,
        'lapse.defaultReminderOffsets': ['x'],
        'lapse.onboardingDone': 'yes',
      },
    )).load();

    expect(settings.themeMode, AppThemeMode.system);
    expect(settings.reminderMinutes, AppSettings.defaultReminderMinutes);
    expect(
      settings.defaultReminderOffsets,
      AppSettings.standardReminderOffsets,
    );
    expect(settings.onboardingDone, isFalse);
  });

  test('AppSettings value semantics', () {
    final a = AppSettings(defaultCurrency: 'PKR');
    expect(a.copyWith(), a);
    expect(a.copyWith().hashCode, a.hashCode);
    expect(a.copyWith(themeMode: AppThemeMode.dark) == a, isFalse);
    expect(a.toString(), contains('PKR'));
    expect(AppThemeMode.fromStorage(null), isNull);
    expect(AppThemeMode.fromStorage('light'), AppThemeMode.light);
  });
}
