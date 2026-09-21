import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../helpers/subscription_fixtures.dart';
import '../../../../helpers/test_database.dart';

void main() {
  late Database db;
  late SubscriptionRepositoryImpl repository;

  setUp(() async {
    db = await openTestDatabase();
    repository = SubscriptionRepositoryImpl(db);
  });

  tearDown(() async {
    await repository.dispose();
    await db.close();
  });

  Charge charge(String id, CalendarDate on, {String sub = 'sub-1'}) => Charge(
    id: id,
    subscriptionId: sub,
    amount: const Money(29900, 'PKR'),
    chargedOn: on,
  );

  test('chargesBetween is inclusive at both ends and ordered', () async {
    await repository.applyRollOver(subscriptionFixture(), [
      charge('late', CalendarDate(2026, 9, 30)),
      charge('before', CalendarDate(2026, 8, 31)),
      charge('first', CalendarDate(2026, 9, 1)),
      charge('after', CalendarDate(2026, 10, 1)),
      charge('mid', CalendarDate(2026, 9, 15)),
    ]);
    await repository.applyRollOver(subscriptionFixture(id: 'sub-2'), [
      charge('other', CalendarDate(2026, 9, 10), sub: 'sub-2'),
    ]);

    final result = await repository.chargesBetween(
      CalendarDate(2026, 9, 1),
      CalendarDate(2026, 9, 30),
    );

    expect(result.map((c) => c.id), ['first', 'other', 'mid', 'late']);
    expect(result.first, charge('first', CalendarDate(2026, 9, 1)));
  });

  test('chargesBetween on a single day and an empty range', () async {
    await repository.applyRollOver(subscriptionFixture(), [
      charge('a', CalendarDate(2026, 9, 5)),
    ]);

    final day = CalendarDate(2026, 9, 5);
    expect(await repository.chargesBetween(day, day), hasLength(1));
    expect(
      await repository.chargesBetween(
        CalendarDate(2026, 9, 6),
        CalendarDate(2026, 9, 30),
      ),
      isEmpty,
    );
  });

  test('chargesBetween drops charges of deleted subscriptions', () async {
    await repository.applyRollOver(subscriptionFixture(), [
      charge('a', CalendarDate(2026, 9, 5)),
    ]);
    await repository.delete('sub-1');

    expect(
      await repository.chargesBetween(
        CalendarDate(2026, 9, 1),
        CalendarDate(2026, 9, 30),
      ),
      isEmpty,
    );
  });
}
