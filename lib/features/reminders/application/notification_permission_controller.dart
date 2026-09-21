import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/features/reminders/application/reminder_providers.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';

class NotificationPermissionController
    extends AsyncNotifier<ReminderPermission> {
  @override
  Future<ReminderPermission> build() =>
      ref.watch(notificationGatewayProvider).permission();

  Future<void> refresh() async {
    ref.invalidate(exactAlarmsAllowedProvider);
    final gateway = ref.read(notificationGatewayProvider);
    final next = await AsyncValue.guard(gateway.permission);
    if (!ref.mounted) return;
    if (next.hasValue && next.value == state.value) return;
    state = next;
  }

  Future<ReminderPermission> request() async {
    final gateway = ref.read(notificationGatewayProvider);
    final result = await gateway.requestPermission();
    if (!ref.mounted) return result;
    state = AsyncData(result);
    ref.invalidate(exactAlarmsAllowedProvider);
    return result;
  }
}
