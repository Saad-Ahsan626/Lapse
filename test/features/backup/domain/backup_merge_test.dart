import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/backup/domain/backup_merge.dart';

import '../../../helpers/subscription_fixtures.dart';
import '../backup_test_data.dart';

void main() {
  final older = DateTime.utc(2026, 9, 2);
  final newer = DateTime.utc(2026, 9, 10);

  test('the later updatedAt wins either way', () {
    final localNewer = subscriptionFixture(
      id: 'a',
      name: 'Local A',
    ).copyWith(updatedAt: newer);
    final incomingOlder = subscriptionFixture(
      id: 'a',
      name: 'Backup A',
    ).copyWith(updatedAt: older);
    final localOlder = subscriptionFixture(
      id: 'b',
      name: 'Local B',
    ).copyWith(updatedAt: older);
    final incomingNewer = subscriptionFixture(
      id: 'b',
      name: 'Backup B',
    ).copyWith(updatedAt: newer);

    final merged = BackupMerge.merge(
      local: [localNewer, localOlder],
      localCharges: const [],
      incoming: [incomingOlder, incomingNewer],
      incomingCharges: const [],
    );

    expect(merged.subscriptions, [localNewer, incomingNewer]);
  });

  test('a tie keeps the local copy', () {
    final local = subscriptionFixture(id: 'a', name: 'Local');
    final incoming = subscriptionFixture(id: 'a', name: 'Backup');

    final merged = BackupMerge.merge(
      local: [local],
      localCharges: const [],
      incoming: [incoming],
      incomingCharges: const [],
    );

    expect(merged.subscriptions, [local]);
  });

  test('adds missing subscriptions and keeps local-only ones', () {
    final local = subscriptionFixture(id: 'a');
    final incoming = subscriptionFixture(id: 'b');

    final merged = BackupMerge.merge(
      local: [local],
      localCharges: const [],
      incoming: [incoming],
      incomingCharges: const [],
    );

    expect(merged.subscriptions, [local, incoming]);
  });

  test('adds charges by id without duplicating', () {
    final kept = chargeFixture('c-1', subscriptionId: 'a');
    final sameId = chargeFixture('c-1', subscriptionId: 'a', minor: 1);
    final added = chargeFixture(
      'c-2',
      subscriptionId: 'a',
      on: CalendarDate(2026, 9, 30),
    );

    final merged = BackupMerge.merge(
      local: [subscriptionFixture(id: 'a')],
      localCharges: [kept],
      incoming: [subscriptionFixture(id: 'a')],
      incomingCharges: [sameId, added, added],
    );

    expect(merged.charges, [kept, added]);
  });
  test('two devices rolled over the same date keep one charge', () {
    final phone = chargeFixture(
      'phone-1',
      subscriptionId: 'a',
      on: CalendarDate(2026, 9, 1),
    );
    final tablet = chargeFixture(
      'tablet-1',
      subscriptionId: 'a',
      on: CalendarDate(2026, 9, 1),
    );
    final otherSubscription = chargeFixture(
      'tablet-2',
      subscriptionId: 'b',
      on: CalendarDate(2026, 9, 1),
    );

    final merged = BackupMerge.merge(
      local: [subscriptionFixture(id: 'a')],
      localCharges: [phone],
      incoming: [
        subscriptionFixture(id: 'a'),
        subscriptionFixture(id: 'b'),
      ],
      incomingCharges: [tablet, otherSubscription],
    );

    expect(merged.charges, [phone, otherSubscription]);
  });
}
