import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/core/providers/storage_providers.dart';
import 'package:lapse/features/reminders/data/memory_reminder_plan_store.dart';
import 'package:lapse/features/reminders/data/reminder_plan_store.dart';
import 'package:lapse/features/reminders/data/sqlite_reminder_plan_store.dart';

final reminderPlanStoreProvider = Provider<ReminderPlanStore>((ref) {
  try {
    return SqliteReminderPlanStore(ref.watch(databaseProvider));
  } on Object {
    return MemoryReminderPlanStore();
  }
});
