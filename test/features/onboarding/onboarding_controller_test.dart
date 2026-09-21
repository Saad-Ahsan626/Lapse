import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/providers/storage_providers.dart';
import 'package:lapse/features/onboarding/presentation/providers/onboarding_controller.dart';
import 'package:lapse/features/settings/domain/entities/app_settings.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';

import '../../helpers/in_memory_settings_repository.dart';

void main() {
  late InMemorySettingsRepository settings;

  ProviderContainer make({AppSettings? initial, String? country = 'IN'}) {
    settings = InMemorySettingsRepository(initial);
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settings),
        deviceCountryProvider.overrideWithValue(country),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('starts from the saved settings', () {
    final container = make(
      initial: AppSettings(defaultCurrency: 'GBP', reminderMinutes: 1200),
    );

    expect(container.read(onboardingControllerProvider), (
      currency: 'GBP',
      minutes: 1200,
    ));
  });

  test('falls back to the device currency when none is saved', () {
    final container = make(initial: AppSettings(defaultCurrency: ' '));

    expect(container.read(onboardingControllerProvider).currency, 'INR');
    expect(
      container.read(onboardingControllerProvider.notifier).deviceCurrency,
      'INR',
    );
    expect(
      container.read(onboardingControllerProvider).minutes,
      AppSettings.defaultReminderMinutes,
    );
  });

  test('edits stay in the draft until saved', () async {
    final container = make();
    container.read(onboardingControllerProvider.notifier)
      ..setCurrency('eur')
      ..setMinutes(20 * 60 + 15);

    expect(container.read(onboardingControllerProvider), (
      currency: 'EUR',
      minutes: 1215,
    ));
    expect(settings.load().defaultCurrency, 'PKR');
    expect(settings.load().reminderMinutes, 540);

    await container.read(onboardingControllerProvider.notifier).saveDefaults();

    expect(settings.load().defaultCurrency, 'EUR');
    expect(settings.load().reminderMinutes, 1215);
    expect(container.read(settingsProvider).defaultCurrency, 'EUR');
    expect(settings.load().onboardingDone, isFalse);
  });

  test('ignores a blank currency and wraps minutes into a day', () {
    final container = make();
    container.read(onboardingControllerProvider.notifier)
      ..setCurrency('  ')
      ..setMinutes(24 * 60 + 30);

    expect(container.read(onboardingControllerProvider), (
      currency: 'PKR',
      minutes: 30,
    ));
  });

  test('finish marks onboarding done', () async {
    final container = make();

    await container.read(onboardingControllerProvider.notifier).finish();

    expect(settings.load().onboardingDone, isTrue);
    expect(container.read(settingsProvider).onboardingDone, isTrue);
  });
}
