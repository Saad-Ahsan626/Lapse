abstract interface class ReminderPlanStore {
  Future<Map<int, String>> load();

  Future<void> save(Map<int, String> plan);

  Future<void> clear();
}
