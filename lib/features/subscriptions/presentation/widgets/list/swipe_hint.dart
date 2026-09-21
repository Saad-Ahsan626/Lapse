import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_tab.dart';

class SwipeHint extends StatelessWidget {
  const SwipeHint({required this.tab, super.key});

  final SubscriptionTab tab;

  String get message => tab == SubscriptionTab.cancelled
      ? 'Swipe a row left for Restore or Delete'
      : 'Swipe a row left for Mark cancelled or Delete';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.screen,
        vertical: Space.lg,
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: context.lapse.text.meta,
      ),
    );
  }
}
