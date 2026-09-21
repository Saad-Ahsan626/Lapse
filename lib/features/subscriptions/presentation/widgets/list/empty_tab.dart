import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_tab.dart';

class EmptyTab extends StatelessWidget {
  const EmptyTab({required this.tab, this.onAdd, super.key});

  final SubscriptionTab tab;
  final VoidCallback? onAdd;

  static const double ringSize = 96;

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    final (title, message, icon, color) = switch (tab) {
      SubscriptionTab.active => (
        'No active subscriptions',
        'Add one and Lapse will keep an eye on it.',
        Icons.receipt_long_rounded,
        c.primary,
      ),
      SubscriptionTab.trials => (
        'No free trials running',
        'Add a trial to get a reminder before it charges.',
        Icons.hourglass_empty_rounded,
        c.trial,
      ),
      SubscriptionTab.cancelled => (
        'Nothing cancelled yet',
        'Subscriptions you cancel show up here with what you saved.',
        Icons.savings_outlined,
        c.savings,
      ),
    };
    final showAdd = tab == SubscriptionTab.active && onAdd != null;

    return EmptyState(
      illustration: ExcludeSemantics(
        child: CountdownRing(
          progress: 1,
          color: color,
          size: ringSize,
          strokeRatio: 0.08,
          animate: false,
          child: Icon(icon, size: 36, color: color),
        ),
      ),
      title: title,
      message: message,
      primaryLabel: showAdd ? 'Add subscription' : null,
      onPrimary: showAdd ? onAdd : null,
    );
  }
}
