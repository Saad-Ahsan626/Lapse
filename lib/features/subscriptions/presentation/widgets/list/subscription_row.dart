import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/core/domain/urgency.dart';
import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:lapse/features/savings/presentation/celebration.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/actions/subscription_actions.dart';
import 'package:lapse/features/subscriptions/presentation/formatting/subscription_labels.dart';

class SubscriptionRow extends ConsumerStatefulWidget {
  const SubscriptionRow({
    required this.subscription,
    this.onTap,
    super.key,
  });

  final Subscription subscription;
  final VoidCallback? onTap;

  static const Duration collapseDuration = Duration(milliseconds: 260);

  static String heroTagFor(Subscription subscription) =>
      'tile-${subscription.id}';

  @override
  ConsumerState<SubscriptionRow> createState() => _SubscriptionRowState();
}

class _SubscriptionRowState extends ConsumerState<SubscriptionRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _collapse = AnimationController(
    vsync: this,
    duration: SubscriptionRow.collapseDuration,
    value: 1,
  );
  late final Animation<double> _size = CurvedAnimation(
    parent: _collapse,
    curve: Curves.easeInOutCubic,
  );
  bool _busy = false;

  @override
  void dispose() {
    _collapse.dispose();
    super.dispose();
  }

  Future<void> _markCancelled() async {
    if (_busy) return;
    _busy = true;
    try {
      if (reduceMotion(context)) {
        _collapse.value = 0;
      } else {
        await _collapse.reverse();
      }
      if (!mounted) return;
      await markCancelledWithCelebration(context, ref, widget.subscription);
    } finally {
      _busy = false;
      if (mounted) _expand();
    }
  }

  void _expand() {
    if (reduceMotion(context)) {
      _collapse.value = 1;
    } else {
      unawaited(_collapse.forward());
    }
  }

  List<SwipeAction> _actions(BuildContext context) {
    final c = context.lapse.colors;
    final s = widget.subscription;
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
        onTap: () => unawaited(_markCancelled()),
      ),
      delete,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.subscription;
    final today = ref.watch(todayProvider);
    final key = s.catalogKey;
    final service = key == null
        ? null
        : ref.watch(catalogServiceByKeyProvider(key));
    final hasLogo =
        key != null &&
        (ref.watch(logoAvailabilityProvider).value?.hasLogo(key) ?? false);
    final cancelled = s.isCancelled;

    return SizeTransition(
      sizeFactor: _size,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _size,
        child: SwipeActions(
          actions: _actions(context),
          child: SubscriptionListTile(
            name: s.name,
            meta: metaLabel(s),
            dueLabel: cancelled ? cancelledLabel(s) : dueLabel(s, today),
            urgency: cancelled ? Urgency.normal : urgencyOf(s, today),
            isTrial: s.isTrial && !cancelled,
            initials: service?.initials,
            brandColor: service == null ? null : Color(service.brandColor),
            logoAsset: hasLogo ? service?.logoAsset : null,
            heroTag: SubscriptionRow.heroTagFor(s),
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}
