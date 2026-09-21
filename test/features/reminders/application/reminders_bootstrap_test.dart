import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/app/router/app_router.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/features/reminders/application/reminders_bootstrap.dart';
import 'package:lapse/features/reminders/data/notification_launch.dart';
import 'package:lapse/features/reminders/data/notification_tap.dart';
import 'package:lapse/features/settings/domain/entities/app_settings.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';

import '../../../helpers/fake_notification_gateway.dart';
import '../../../helpers/in_memory_settings_repository.dart';
import 'reminder_test_support.dart';

class _BrokenGateway extends FakeNotificationGateway {
  @override
  Future<void> initialize({
    required void Function(NotificationTap tap) onTap,
  }) => Future.error(StateError('plugin missing'));
}

void main() {
  const launch = NotificationLaunch(
    NotificationTap(subscriptionId: 'sub-7', action: NotificationAction.open),
  );

  test('initial location is the splash without a launch tap', () {
    expect(initialLocationFor(null), Routes.splash);
  });

  test('initial location is the tapped detail on a cold start', () {
    expect(initialLocationFor(launch), Routes.detail('sub-7'));
  });

  test('bootstrap returns the launch tap after initializing', () async {
    final h = ReminderHarness(gateway: FakeNotificationGateway(launch: launch));
    final container = h.container();
    addTearDown(container.dispose);

    expect(await bootstrapReminders(container), launch);
    expect(h.gateway.isInitialized, isTrue);
    expect(h.timezoneCalls, 1);
  });

  test('bootstrap never throws', () async {
    final h = ReminderHarness(gateway: _BrokenGateway());
    final container = h.container();
    addTearDown(container.dispose);

    expect(await bootstrapReminders(container), isNull);
  });

  test('the router starts at the initial location', () {
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          InMemorySettingsRepository(
            AppSettings(defaultCurrency: 'PKR', onboardingDone: true),
          ),
        ),
        initialLocationProvider.overrideWithValue(initialLocationFor(launch)),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);

    expect(
      router.routeInformationProvider.value.uri.path,
      Routes.detail('sub-7'),
    );
  });

  test('the router starts at the splash by default', () {
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          InMemorySettingsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      Routes.splash,
    );
  });
}
