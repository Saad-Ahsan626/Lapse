import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/home/presentation/widgets/trial_card.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';

class TrialsStrip extends StatelessWidget {
  const TrialsStrip({required this.trials, required this.today, super.key});

  final List<Subscription> trials;
  final CalendarDate today;

  @override
  Widget build(BuildContext context) {
    if (trials.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            0,
            Space.screen - Space.sm,
            Space.sm,
          ),
          child: SectionHeader(
            title: 'Trials ending soon',
            actionLabel: 'See all',
            onAction: () => unawaited(
              context.push<void>(Routes.subscriptionsTab('trials')),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: Space.screen),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < trials.length; i++) ...[
                  if (i > 0) const SizedBox(width: Space.md),
                  StaggeredEntrance(
                    index: i,
                    child: TrialCard(
                      subscription: trials[i],
                      today: today,
                      onTap: () => unawaited(
                        context.push<void>(Routes.detail(trials[i].id)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
