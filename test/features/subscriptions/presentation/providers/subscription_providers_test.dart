import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/core/providers/storage_providers.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_list_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../helpers/subscription_fixtures.dart';
import '../../../../helpers/test_database.dart';

void main() {
  late Database db;
  late ProviderContainer container;

  setUp(() async {
    db = await openTestDatabase();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => DateTime(2026, 9, 19, 10)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> expectNames(
    ProviderListenable<AsyncValue<List<Subscription>>> provider,
    Object expected,
  ) async {
    final matcher = wrapMatcher(expected);
    var current = <String>[];
    for (var attempt = 0; attempt < 200; attempt++) {
      final value = container.read(provider);
      if (value.hasValue) {
        current = value.requireValue.map((s) => s.name).toList();
        if (matcher.matches(current, {})) break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(current, expected);
  }

  test('lists split into active, trials and cancelled', () async {
    container.listen(subscriptionsProvider, (_, _) {});
    final save = container.read(saveSubscriptionProvider);

    final spotify = await save(
      subscriptionFixture(id: Subscription.unsavedId),
    );
    await save(
      subscriptionFixture(
        id: Subscription.unsavedId,
        name: 'Netflix',
        isTrial: true,
      ),
    );

    await expectNames(activeSubscriptionsProvider, ['Spotify Premium']);
    await expectNames(trialSubscriptionsProvider, ['Netflix']);
    await expectNames(cancelledSubscriptionsProvider, isEmpty);

    await container.read(markCancelledProvider)(spotify.id);

    await expectNames(activeSubscriptionsProvider, isEmpty);
    await expectNames(cancelledSubscriptionsProvider, ['Spotify Premium']);
  });

  test('clock offset moves today', () {
    final real = ProviderContainer();
    addTearDown(real.dispose);
    final before = real.read(todayProvider);

    real.read(clockOffsetProvider.notifier).travel(const Duration(days: 30));

    expect(before.daysUntil(real.read(todayProvider)), 30);
    real.read(clockOffsetProvider.notifier).reset();
    expect(real.read(todayProvider), before);
  });

  test('today follows the clock', () {
    expect(container.read(todayProvider), CalendarDate(2026, 9, 19));
  });

  test('ids are unique', () {
    final newId = container.read(newIdProvider);
    expect(newId(), isNot(newId()));
  });
}
