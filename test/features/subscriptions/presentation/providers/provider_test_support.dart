import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/features/settings/domain/entities/app_settings.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_list_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

import '../../../../helpers/fake_subscription_repository.dart';
import '../../../../helpers/in_memory_settings_repository.dart';
import '../../../../helpers/test_clock.dart';

class ProviderHarness {
  ProviderHarness({DateTime? now, String currency = 'PKR'})
    : clock = TestClock(now ?? DateTime(2026, 9, 19, 10)),
      repository = FakeSubscriptionRepository() {
    container = ProviderContainer(
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(repository),
        settingsRepositoryProvider.overrideWithValue(
          InMemorySettingsRepository(AppSettings(defaultCurrency: currency)),
        ),
        clockProvider.overrideWithValue(clock.call),
        newIdProvider.overrideWithValue(SequentialIds().call),
      ],
    );
  }

  final TestClock clock;
  final FakeSubscriptionRepository repository;
  late final ProviderContainer container;

  Future<T> read<T>(ProviderListenable<AsyncValue<T>> provider) async {
    container.listen(provider, (_, _) {});
    await container.read(subscriptionsProvider.future);
    await pumpEventQueue();
    return container.read(provider).requireValue;
  }

  void dispose() => container.dispose();
}
