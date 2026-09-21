import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/features/settings/presentation/providers/notification_health_provider.dart';

class NotificationHealthRefresher extends ConsumerStatefulWidget {
  const NotificationHealthRefresher({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<NotificationHealthRefresher> createState() =>
      _NotificationHealthRefresherState();
}

class _NotificationHealthRefresherState
    extends ConsumerState<NotificationHealthRefresher> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onResume: _refresh);
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    unawaited(refreshNotificationHealth(ref));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
