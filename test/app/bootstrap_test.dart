import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/app/bootstrap.dart';
import 'package:lapse/features/settings/domain/entities/app_settings.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';

import '../features/reminders/application/reminder_test_support.dart';
import '../helpers/fake_subscription_repository.dart';
import '../helpers/in_memory_settings_repository.dart';
import '../helpers/subscription_fixtures.dart';

class _FailingRepository extends FakeSubscriptionRepository {
  @override
  Future<List<Subscription>> getAll() => Future.error(StateError('no db'));
}

void main() {
  ReminderHarness harness({
    bool onboardingDone = false,
    FakeSubscriptionRepository? repository,
  }) => ReminderHarness(
    repository: repository,
    settings: InMemorySettingsRepository(
      AppSettings(defaultCurrency: 'PKR', onboardingDone: onboardingDone),
    ),
  );

  test('an existing install with subscriptions skips onboarding', () async {
    final h = harness()..repository.seed([subscriptionFixture()]);
    final container = h.container();
    addTearDown(container.dispose);

    await skipOnboardingForExistingInstall(container);

    expect(h.settings.load().onboardingDone, isTrue);
    expect(container.read(settingsProvider).onboardingDone, isTrue);
  });

  test('a fresh install still goes through onboarding', () async {
    final h = harness();
    final container = h.container();
    addTearDown(container.dispose);

    await skipOnboardingForExistingInstall(container);

    expect(h.settings.load().onboardingDone, isFalse);
    expect(h.settings.saveCount, 0);
  });

  test('does nothing when onboarding is already done', () async {
    final h = harness(onboardingDone: true)
      ..repository.seed([subscriptionFixture()]);
    final container = h.container();
    addTearDown(container.dispose);

    await skipOnboardingForExistingInstall(container);

    expect(h.settings.saveCount, 0);
  });

  test('a database error never blocks the launch', () async {
    final h = harness(repository: _FailingRepository());
    final container = h.container();
    addTearDown(container.dispose);

    await expectLater(skipOnboardingForExistingInstall(container), completes);
    expect(h.settings.load().onboardingDone, isFalse);
  });
}
