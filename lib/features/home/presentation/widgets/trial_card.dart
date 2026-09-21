import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/home/presentation/widgets/subscription_brand.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/formatting/subscription_labels.dart';

class TrialCard extends ConsumerWidget {
  const TrialCard({
    required this.subscription,
    required this.today,
    required this.onTap,
    super.key,
  });

  final Subscription subscription;
  final CalendarDate today;
  final VoidCallback onTap;

  static const double width = 196;
  static const double maxWidth = 300;
  static const double tileSize = 40;

  static double widthFor(BuildContext context) => math.min(
    MediaQuery.textScalerOf(context).scale(width),
    maxWidth,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.lapse.text;
    final brand = SubscriptionBrand.watch(ref, subscription);
    final meta = metaLabel(subscription);
    final due = dueLabel(subscription, today);

    return SizedBox(
      width: widthFor(context),
      child: Semantics(
        button: true,
        label: SubscriptionListTile.semanticLabelFor(
          name: subscription.name,
          state: 'free trial',
          amount: spokenAmountLabel(subscription),
          when: spokenDueLabel(subscription, today),
        ),
        excludeSemantics: true,
        onTap: onTap,
        child: LapseCard(
          onTap: onTap,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ServiceTile(
                    name: subscription.name,
                    initials: brand.initials,
                    brandColor: brand.brandColor,
                    logoAsset: brand.logoAsset,
                    size: tileSize,
                    heroTag: SubscriptionBrand.heroTagFor(subscription),
                  ),
                  const Spacer(),
                  const TrialBadge(),
                ],
              ),
              const SizedBox(height: Space.md),
              Text(
                subscription.name,
                style: text.itemTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                meta,
                style: text.meta,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              const SizedBox(height: Space.md),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: UrgencyChip(
                  label: due,
                  urgency: urgencyOf(subscription, today),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
