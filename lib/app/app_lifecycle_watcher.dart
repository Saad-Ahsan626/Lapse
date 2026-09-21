import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/core/providers/clock_providers.dart';
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

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onResume: _handleResume);
    WidgetsBinding.instance.addPostFrameCallback((_) => _rollOver());
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  void _handleResume() {
    if (!mounted) return;
    ref.read(dayTickProvider.notifier).bump();
    _rollOver();
  }

  void _rollOver() {
    if (!mounted) return;
    unawaited(_safely(() => ref.read(rollOverDueSubscriptionsProvider)()));
  }

  Future<void> _safely(Future<int> Function() run) async {
    try {
      await run();
    } on Object {
      return;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
