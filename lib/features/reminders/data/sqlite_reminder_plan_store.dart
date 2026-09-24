import 'package:lapse/core/database/schema.dart';
import 'package:lapse/features/reminders/data/reminder_plan_store.dart';
import 'package:sqflite/sqflite.dart';

class SqliteReminderPlanStore implements ReminderPlanStore {
  const SqliteReminderPlanStore(this._db);

  final Database _db;

  @override
  Future<Map<int, String>> load() async {
    final rows = await _db.query(Tables.reminderPlan);
    return {
      for (final row in rows) row['id']! as int: row['signature']! as String,
    };
  }

  @override
  Future<void> save(Map<int, String> plan) => _db.transaction((txn) async {
    final batch = txn.batch()..delete(Tables.reminderPlan);
    for (final entry in plan.entries) {
      batch.insert(Tables.reminderPlan, {
        'id': entry.key,
        'signature': entry.value,
      });
    }
    await batch.commit(noResult: true);
  });

  @override
  Future<void> clear() => _db.delete(Tables.reminderPlan);
}
