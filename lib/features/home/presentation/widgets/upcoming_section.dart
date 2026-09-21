import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/home/presentation/widgets/upcoming_row.dart';
import 'package:lapse/features/subscriptions/presentation/providers/upcoming_charges.dart';

class UpcomingSection extends StatelessWidget {
  const UpcomingSection({
    required this.upcoming,
    required this.today,
    required this.hasTrials,
    super.key,
  });

  final UpcomingCharges upcoming;
  final CalendarDate today;
  final bool hasTrials;

  @override
  Widget build(BuildContext context) {
    final text = context.lapse.text;
    final items = upcoming.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  upcoming.isThisMonth ? 'Upcoming charges' : 'Coming up',
                  style: text.section,
                ),
              ),
              if (upcoming.isThisMonth) ...[
                const SizedBox(width: Space.md),
                Text('This month', style: text.meta.copyWith(fontSize: 13.5)),
              ],
            ],
          ),
        ),
        const SizedBox(height: Space.md),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.sm),
            child: Text(
              hasTrials ? 'No other charges coming up' : 'No charges coming up',
              style: text.bodyMuted,
            ),
          )
        else
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            StaggeredEntrance(
              index: i,
              child: UpcomingRow(
                subscription: items[i],
                today: today,
                onTap: () => unawaited(
                  context.push<void>(Routes.detail(items[i].id)),
                ),
              ),
            ),
          ],
        const SizedBox(height: Space.md),
        Center(
          child: LapseButton(
            label: 'All subscriptions',
            variant: LapseButtonVariant.text,
            trailingIcon: Icons.chevron_right_rounded,
            onPressed: () =>
                unawaited(context.push<void>(Routes.subscriptions)),
          ),
        ),
      ],
    );
  }
}
