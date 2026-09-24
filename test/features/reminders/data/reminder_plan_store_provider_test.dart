import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/providers/storage_providers.dart';
import 'package:lapse/features/reminders/data/memory_reminder_plan_store.dart';
import 'package:lapse/features/reminders/data/reminder_plan_store_provider.dart';
import 'package:lapse/features/reminders/data/sqlite_reminder_plan_store.dart';

import '../../../helpers/test_database.dart';

void main() {
  test('uses the app database when it is available', () async {
    final db = await openTestDatabase();
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final store = container.read(reminderPlanStoreProvider);

    expect(store, isA<SqliteReminderPlanStore>());
    await store.save({7: 'x'});
    expect(await store.load(), {7: 'x'});
  });

  test('falls back to memory without a database', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final store = container.read(reminderPlanStoreProvider);

    expect(store, isA<MemoryReminderPlanStore>());
    await store.save({1: 'a'});
    expect(await container.read(reminderPlanStoreProvider).load(), {1: 'a'});
  });
}
