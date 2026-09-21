import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/core/domain/urgency.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/actions/subscription_actions.dart';
import 'package:lapse/features/subscriptions/presentation/formatting/subscription_labels.dart';

class SubscriptionRow extends ConsumerWidget {
  const SubscriptionRow({
    required this.subscription,
    this.onTap,
    super.key,
  });

  final Subscription subscription;
  final VoidCallback? onTap;

  static String heroTagFor(Subscription subscription) =>
      'tile-${subscription.id}';

  List<SwipeAction> _actions(BuildContext context, WidgetRef ref) {
    final c = context.lapse.colors;
    final s = subscription;
    final delete = SwipeAction(
      label: 'Delete',
      icon: Icons.delete_outline_rounded,
      color: c.urgent,
      foregroundColor: c.onTrial,
      onTap: () => unawaited(confirmAndDelete(context, ref, s)),
    );
    if (s.isCancelled) {
      return [
        SwipeAction(
          label: 'Restore',
          icon: Icons.undo_rounded,
          color: c.primary,
          foregroundColor: c.onPrimary,
          onTap: () => unawaited(restoreWithFeedback(context, ref, s)),
        ),
        delete,
      ];
    }
    return [
      SwipeAction(
        label: 'Cancelled',
        icon: Icons.check_rounded,
        color: c.savings,
        foregroundColor: c.onTrial,
        onTap: () => unawaited(markCancelledWithUndo(context, ref, s)),
      ),
      delete,
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = subscription;
    final today = ref.watch(todayProvider);
    final key = s.catalogKey;
    final service = key == null
        ? null
        : ref.watch(catalogServiceByKeyProvider(key));
    final hasLogo =
        key != null &&
        (ref.watch(logoAvailabilityProvider).value?.hasLogo(key) ?? false);
    final cancelled = s.isCancelled;

    return SwipeActions(
      actions: _actions(context, ref),
      child: SubscriptionListTile(
        name: s.name,
        meta: metaLabel(s),
        dueLabel: cancelled ? cancelledLabel(s) : dueLabel(s, today),
        urgency: cancelled ? Urgency.normal : urgencyOf(s, today),
        isTrial: s.isTrial && !cancelled,
        initials: service?.initials,
        brandColor: service == null ? null : Color(service.brandColor),
        logoAsset: hasLogo ? service?.logoAsset : null,
        heroTag: heroTagFor(s),
        onTap: onTap,
      ),
    );
  }
}
