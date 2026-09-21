import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/features/reminders/application/reminder_providers.dart';
import 'package:lapse/features/reminders/application/reminder_sync_result.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

class AppLifecycleWatcher extends ConsumerStatefulWidget {
  const AppLifecycleWatcher({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppLifecycleWatcher> createState() =>
      _AppLifecycleWatcherState();
}

class _AppLifecycleWatcherState extends ConsumerState<AppLifecycleWatcher> {
  late final AppLifecycleListener _listener;
  ProviderSubscription<ReminderSyncResult?>? _reminderSync;
  String? _timezone;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onResume: _handleResume);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleFirstFrame());
  }

  @override
  void dispose() {
    _listener.dispose();
    _reminderSync?.close();
    super.dispose();
  }

  void _handleFirstFrame() {
    if (!mounted) return;
    _rollOver();
    _reminderSync ??= ref.listenManual(reminderSyncProvider, (_, _) {});
    unawaited(_checkTimezone());
  }

  void _handleResume() {
    if (!mounted) return;
    ref.read(dayTickProvider.notifier).bump();
    _rollOver();
    unawaited(
      _safely(ref.read(notificationPermissionProvider.notifier).refresh),
    );
    unawaited(_checkTimezone());
  }

  void _rollOver() {
    if (!mounted) return;
    unawaited(_safely(() => ref.read(rollOverDueSubscriptionsProvider)()));
  }

  Future<void> _checkTimezone() async {
    try {
      final zone = await ref.read(configureTimezoneProvider)();
      if (!mounted) return;
      final changed = _timezone != null && _timezone != zone;
      _timezone = zone;
      if (changed) {
        await ref.read(reminderSyncProvider.notifier).syncNow();
      }
    } on Object {
      return;
    }
  }

  Future<void> _safely(Future<Object?> Function() run) async {
    try {
      await run();
    } on Object {
      return;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
