import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_detail.dart';

class DetailRing extends StatelessWidget {
  const DetailRing({required this.detail, super.key});

  static const double size = 180;
  static const double strokeRatio = 0.075;

  final SubscriptionDetail detail;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    final urgencyText = c.urgencyChip(detail.urgency).foreground;
    final bigStyle = lapse.text.moneyHero.copyWith(
      fontSize: 48,
      fontWeight: FontWeight.w800,
      height: 1.05,
      letterSpacing: -1.5,
      color: c.ink,
    );
    final wordStyle = bigStyle.copyWith(fontSize: 34, letterSpacing: -0.8);
    final labelStyle = lapse.text.body.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: urgencyText,
    );

    final (
      double progress,
      Color color,
      Widget centre,
      String semantics,
    ) = switch (detail.ringState) {
      DetailRingState.upcoming => (
        detail.progress,
        c.urgencyAccent(detail.urgency),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${detail.daysLeft}', style: bigStyle),
            Text(_daysLeftLabel(detail.daysLeft), style: labelStyle),
          ],
        ),
        '${detail.daysLeft} ${_daysLeftLabel(detail.daysLeft)}',
      ),
      DetailRingState.today => (
        1.0,
        c.urgent,
        Text('Today', style: wordStyle),
        'Charges today',
      ),
      DetailRingState.overdue => (
        1.0,
        c.urgent,
        Text('Due', style: wordStyle),
        'Payment due',
      ),
      DetailRingState.cancelled => (
        1.0,
        c.inkSubtle,
        Text('Cancelled', style: lapse.text.section),
        'Cancelled',
      ),
    };

    return CountdownRing(
      semanticLabel: semantics,
      progress: progress,
      color: color,
      size: size,
      strokeRatio: strokeRatio,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Padding(
          padding: const EdgeInsets.all(size * strokeRatio * 2),
          child: FittedBox(fit: BoxFit.scaleDown, child: centre),
        ),
      ),
    );
  }

  static String _daysLeftLabel(int days) =>
      days == 1 ? 'day left' : 'days left';
}
