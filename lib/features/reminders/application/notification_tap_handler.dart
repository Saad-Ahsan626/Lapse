import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/features/reminders/data/notification_launch.dart';
import 'package:lapse/features/reminders/data/notification_tap.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:lapse/features/subscriptions/presentation/links/cancel_links.dart';
import 'package:lapse/features/subscriptions/presentation/links/link_opener.dart';

class NotificationTapHandler {
  const NotificationTapHandler({
    required GoRouter router,
    required SubscriptionRepository repository,
    required LinkOpener linkOpener,
    required Future<void> Function(String subscriptionId) snooze,
  }) : _router = router,
       _repository = repository,
       _linkOpener = linkOpener,
       _snooze = snooze;

  final GoRouter _router;
  final SubscriptionRepository _repository;
  final LinkOpener _linkOpener;
  final Future<void> Function(String subscriptionId) _snooze;

  Future<void> handle(NotificationTap tap) async {
    final subscription = await _find(tap.subscriptionId);
    if (tap.action == NotificationAction.snooze) {
      if (subscription != null) await _snooze(subscription.id);
      return;
    }
    if (subscription == null) {
      _router.go(Routes.home);
      return;
    }
    if (tap.action == NotificationAction.cancelNow &&
        await _openCancelLink(subscription)) {
      return;
    }
    if (_isShowing(subscription.id)) return;
    unawaited(_router.push<void>(Routes.detail(subscription.id)));
  }

  bool _isShowing(String id) {
    if (_router.routerDelegate.currentConfiguration.isEmpty) return false;
    final path = _router.state.uri.path;
    return path == Routes.detail(id) || path == Routes.edit(id);
  }

  Future<void> handleLaunch(NotificationLaunch launch) async {
    if (launch.tap.action != NotificationAction.cancelNow) return;
    final subscription = await _find(launch.tap.subscriptionId);
    if (subscription == null) {
      _router.go(Routes.home);
      return;
    }
    await _openCancelLink(subscription);
  }

  Future<Subscription?> _find(String id) async {
    try {
      return await _repository.getById(id);
    } on Object {
      return null;
    }
  }

  Future<bool> _openCancelLink(Subscription subscription) async {
    final uri = cancelUriFor(subscription);
    if (uri == null) return false;
    try {
      return await _linkOpener.open(uri);
    } on Object {
      return false;
    }
  }
}
