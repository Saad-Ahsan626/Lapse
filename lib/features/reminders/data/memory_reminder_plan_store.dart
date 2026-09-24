import 'package:lapse/features/reminders/data/reminder_plan_store.dart';

class MemoryReminderPlanStore implements ReminderPlanStore {
  MemoryReminderPlanStore([Map<int, String>? initial]) : plan = {...?initial};

  Map<int, String> plan;

  @override
  Future<Map<int, String>> load() async => {...plan};

  @override
  Future<void> save(Map<int, String> plan) async {
    this.plan = {...plan};
  }

  @override
  Future<void> clear() async => plan = {};
}
