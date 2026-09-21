import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/home/presentation/widgets/subscription_brand.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/formatting/subscription_labels.dart';

class UpcomingRow extends ConsumerWidget {
  const UpcomingRow({
    required this.subscription,
    required this.today,
    required this.onTap,
    super.key,
  });

  final Subscription subscription;
  final CalendarDate today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = SubscriptionBrand.watch(ref, subscription);
    return SubscriptionListTile(
      name: subscription.name,
      meta: metaLabel(subscription),
      dueLabel: dueLabel(subscription, today),
      urgency: urgencyOf(subscription, today),
      isTrial: subscription.isTrial,
      initials: brand.initials,
      brandColor: brand.brandColor,
      logoAsset: brand.logoAsset,
      heroTag: SubscriptionBrand.heroTagFor(subscription),
      onTap: onTap,
      semanticAmount: spokenAmountLabel(subscription),
      semanticWhen: spokenDueLabel(subscription, today),
    );
  }
}
