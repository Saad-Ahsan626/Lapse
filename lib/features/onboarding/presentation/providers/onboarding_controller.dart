import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/core/domain/currency_for_country.dart';
import 'package:lapse/core/providers/storage_providers.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';

typedef OnboardingDraft = ({String currency, int minutes});

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingDraft>(
      OnboardingController.new,
    );

class OnboardingController extends Notifier<OnboardingDraft> {
  @override
  OnboardingDraft build() {
    final settings = ref.read(settingsProvider);
    final stored = settings.defaultCurrency.trim().toUpperCase();
    return (
      currency: stored.isEmpty ? deviceCurrency : stored,
      minutes: settings.reminderMinutes,
    );
  }

  String get deviceCurrency =>
      currencyForCountry(ref.read(deviceCountryProvider));

  void setCurrency(String code) {
    final upper = code.trim().toUpperCase();
    if (upper.isEmpty) return;
    state = (currency: upper, minutes: state.minutes);
  }

  void setMinutes(int minutes) {
    state = (currency: state.currency, minutes: minutes % (24 * 60));
  }

  Future<void> saveDefaults() {
    final draft = state;
    return ref
        .read(settingsProvider.notifier)
        .update(
          (settings) => settings.copyWith(
            defaultCurrency: draft.currency,
            reminderMinutes: draft.minutes,
          ),
        );
  }

  Future<void> finish() => ref
      .read(settingsProvider.notifier)
      .update((settings) => settings.copyWith(onboardingDone: true));
}
