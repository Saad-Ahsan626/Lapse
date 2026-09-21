import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/app/app_lifecycle_watcher.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

import '../helpers/fake_subscription_repository.dart';
import '../helpers/subscription_fixtures.dart';
import '../helpers/test_clock.dart';

class _FailingRepository extends FakeSubscriptionRepository {
  int calls = 0;

  @override
  Future<List<Subscription>> getAll() {
    calls++;
    return Future.error(StateError('database unavailable'));
  }
}

void main() {
  Future<void> pumpWatcher(
    WidgetTester tester,
    FakeSubscriptionRepository repository,
    TestClock clock,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(repository),
          clockProvider.overrideWithValue(clock.call),
          newIdProvider.overrideWithValue(SequentialIds().call),
        ],
        child: const AppLifecycleWatcher(child: SizedBox()),
      ),
    );
    await tester.pump();
  }

  Future<void> backgroundAndResume(WidgetTester tester) async {
    const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ].forEach(tester.binding.handleAppLifecycleStateChanged);
    await tester.pump();
  }

  testWidgets('rolls over after the first frame and again on resume', (
    tester,
  ) async {
    final clock = TestClock(DateTime(2026, 9, 19, 10));
    final repository = FakeSubscriptionRepository()
      ..seed([subscriptionFixture(nextBillingDate: CalendarDate(2026, 9, 10))]);

    await pumpWatcher(tester, repository, clock);

    expect(
      repository.subscriptions['sub-1']!.nextBillingDate,
      CalendarDate(2026, 10, 10),
    );
    expect(repository.charges, hasLength(1));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SizedBox)),
    );
    expect(container.read(todayProvider), CalendarDate(2026, 9, 19));

    clock.advance(const Duration(days: 30));
    await backgroundAndResume(tester);

    expect(
      repository.subscriptions['sub-1']!.nextBillingDate,
      CalendarDate(2026, 11, 10),
    );
    expect(repository.charges, hasLength(2));
    expect(container.read(todayProvider), CalendarDate(2026, 10, 19));
  });

  testWidgets('roll-over failures do not surface', (tester) async {
    final repository = _FailingRepository();
    final clock = TestClock(DateTime(2026, 9, 19, 10));

    await pumpWatcher(tester, repository, clock);
    await backgroundAndResume(tester);

    expect(tester.takeException(), isNull);
    expect(repository.calls, 2);
    expect(find.byType(SizedBox), findsOneWidget);
  });
}
