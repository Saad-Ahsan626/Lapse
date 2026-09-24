import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';

import 'fake_subscription_repository.dart';
import 'subscription_fixtures.dart';

void main() {
  Charge charge(String id, CalendarDate on) => Charge(
    id: id,
    subscriptionId: 'sub-1',
    amount: const Money(100, 'PKR'),
    chargedOn: on,
  );

  test('fake chargesBetween is inclusive and ordered by date', () async {
    final repository = FakeSubscriptionRepository();
    repository.charges.addAll([
      charge('late', CalendarDate(2026, 9, 30)),
      charge('before', CalendarDate(2026, 8, 31)),
      charge('first', CalendarDate(2026, 9, 1)),
      charge('after', CalendarDate(2026, 10, 1)),
    ]);

    final result = await repository.chargesBetween(
      CalendarDate(2026, 9, 1),
      CalendarDate(2026, 9, 30),
    );

    expect(result.map((c) => c.id), ['first', 'late']);
  });

  test(
    'fake watchAll skips identical data and refresh re-emits changes',
    () async {
      final repository = FakeSubscriptionRepository()
        ..seed([subscriptionFixture()]);
      final names = <String>[];
      final listener = repository.watchAll().listen(
        (list) => names.add(list.single.name),
      );
      await pumpEventQueue();

      await repository.upsert(subscriptionFixture());
      await repository.refresh();
      await pumpEventQueue();
      repository.subscriptions['sub-1'] = subscriptionFixture(name: 'Duo');
      await repository.refresh();
      await pumpEventQueue();
      await listener.cancel();

      expect(names, ['Spotify Premium', 'Duo']);
      expect(repository.refreshCount, 2);
    },
  );
}
