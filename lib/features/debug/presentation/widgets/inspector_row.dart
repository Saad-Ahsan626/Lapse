import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/domain/urgency.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/debug/presentation/formatting/plain_money.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_list_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

class InspectorRow extends ConsumerWidget {
  const InspectorRow({required this.subscription, super.key});

  final Subscription subscription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lapse = context.lapse;
    final engine = ref.watch(billingEngineProvider);
    final today = ref.watch(todayProvider);
    final s = subscription;
    final daysLeft = engine.daysLeft(s, today);
    final charges = ref.watch(chargesProvider(s.id)).value?.length ?? 0;
    final period = s.customDays == null
        ? s.period.name
        : 'every ${s.customDays} days';

    return LapseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ServiceTile(name: s.name, size: 36),
              const SizedBox(width: Space.md),
              Expanded(
                child: Text(
                  s.name,
                  style: lapse.text.itemTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (s.isTrial) ...[
                const TrialBadge(),
                const SizedBox(width: Space.sm),
              ],
              if (s.isActive)
                UrgencyChip(
                  label: '${daysLeft}d',
                  urgency: Urgency.fromDaysLeft(daysLeft),
                ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Text(
            '${plainMoney(s.price)} · $period · anchor ${s.anchorDay}',
            style: lapse.text.meta,
          ),
          Text(
            'next ${s.nextBillingDate} · started ${s.startDate}',
            style: lapse.text.meta,
          ),
          Text(
            'yearly ${plainMoney(engine.yearlyCost(s))} · '
            'monthly ${plainMoney(engine.monthlyEquivalent(s))}',
            style: lapse.text.meta,
          ),
          Text(
            '${s.status.name} · charges $charges · '
            'cycle left ${(engine.cycleProgress(s, today) * 100).round()}%',
            style: lapse.text.meta,
          ),
          const SizedBox(height: Space.xs),
          Wrap(
            children: [
              LapseButton(
                label: 'Edit',
                variant: LapseButtonVariant.text,
                onPressed: () => unawaited(context.push(Routes.edit(s.id))),
              ),
              LapseButton(
                label: s.isActive ? 'Cancel' : 'Restore',
                variant: LapseButtonVariant.text,
                onPressed: () => s.isActive
                    ? ref.read(markCancelledProvider)(s.id)
                    : ref.read(restoreSubscriptionProvider)(s.id),
              ),
              LapseButton(
                label: 'Delete',
                variant: LapseButtonVariant.text,
                onPressed: () => ref.read(deleteSubscriptionProvider)(s.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
