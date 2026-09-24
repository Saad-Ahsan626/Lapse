import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/app/app_ready_controller.dart';
import 'package:lapse/app/router/initial_location_provider.dart';
import 'package:lapse/app/router/routes.dart';
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
  ProviderSubscription<bool>? _appReady;
  bool _startupScheduled = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onResume: _handleResume);
    if (ref.read(initialLocationProvider) != Routes.splash) {
      _scheduleStartup();
      return;
    }
    _appReady = ref.listenManual(appReadyProvider, (_, ready) {
      if (ready) _scheduleStartup();
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _listener.dispose();
    _appReady?.close();
    _reminderSync?.close();
    super.dispose();
  }

  void _scheduleStartup() {
    if (_startupScheduled) return;
    _startupScheduled = true;
    _appReady?.close();
    _appReady = null;
    unawaited(_startAfterNextFrame());
  }

  Future<void> _startAfterNextFrame() async {
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted) return;
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted) return;
    _started = true;
    _rollOver();
    _reminderSync ??= ref.listenManual(reminderSyncProvider, (_, _) {});
    unawaited(_checkTimezone());
  }

  void _handleResume() {
    if (!mounted) return;
    ref.read(dayTickProvider.notifier).bump();
    if (!_started) return;
    unawaited(
      _safely(ref.read(notificationPermissionProvider.notifier).refresh),
    );
    unawaited(_refreshAfterResume());
  }

  Future<void> _refreshAfterResume() async {
    await _checkTimezone();
    if (!mounted) return;
    await _safely(_reloadSubscriptions);
    if (!mounted) return;
    await _safely(() => ref.read(rollOverDueSubscriptionsProvider)());
    if (!mounted) return;
    await _safely(ref.read(reminderSyncProvider.notifier).syncNow);
  }

  Future<void> _reloadSubscriptions() =>
      ref.read(subscriptionRepositoryProvider).refresh();

  void _rollOver() {
    if (!mounted) return;
    unawaited(_safely(() => ref.read(rollOverDueSubscriptionsProvider)()));
  }

  Future<void> _checkTimezone() => _safely(ref.read(configureTimezoneProvider));

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
