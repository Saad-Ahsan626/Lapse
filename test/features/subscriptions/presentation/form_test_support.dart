import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/features/catalog/data/logo_availability.dart';
import 'package:lapse/features/catalog/domain/entities/catalog_service.dart';
import 'package:lapse/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_args.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_controller.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_state.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

import '../../../helpers/fake_catalog_repository.dart';
import '../../../helpers/fake_subscription_repository.dart';
import '../../../helpers/in_memory_settings_repository.dart';
import '../../../helpers/test_clock.dart';

final formToday = CalendarDate(2026, 9, 18);

const netflix = CatalogService(
  key: 'netflix',
  name: 'Netflix',
  category: 'Entertainment',
  initials: 'NF',
  brandColor: 0xFFE50914,
  defaultPeriod: BillingPeriod.monthly,
  cancelUrl: 'https://netflix.com/cancelplan',
);

const icloud = CatalogService(
  key: 'icloud',
  name: 'iCloud+',
  category: 'Storage',
  initials: 'iC',
  brandColor: 0xFF3693F3,
  defaultPeriod: BillingPeriod.yearly,
);

List<Override> formOverrides(
  FakeSubscriptionRepository repository, {
  bool withSettings = true,
}) => [
  subscriptionRepositoryProvider.overrideWithValue(repository),
  if (withSettings)
    settingsRepositoryProvider.overrideWithValue(InMemorySettingsRepository()),
  clockProvider.overrideWithValue(TestClock(DateTime(2026, 9, 18, 10)).call),
  newIdProvider.overrideWithValue(SequentialIds().call),
  catalogRepositoryProvider.overrideWithValue(
    FakeCatalogRepository(const [netflix, icloud]),
  ),
  logoAvailabilityProvider.overrideWith((ref) => LogoAvailability({})),
];

ProviderContainer formContainer(FakeSubscriptionRepository repository) {
  final container = ProviderContainer(overrides: formOverrides(repository));
  addTearDown(container.dispose);
  return container;
}

Future<SubscriptionFormController> openForm(
  ProviderContainer container,
  SubscriptionFormArgs args,
) async {
  final provider = subscriptionFormProvider(args);
  container.listen<SubscriptionFormState>(provider, (_, _) {});
  for (var i = 0; i < 20 && container.read(provider).isLoading; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  return container.read(provider.notifier);
}
