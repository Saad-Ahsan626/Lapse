import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:lapse/features/catalog/presentation/widgets/catalog_result_row.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';

class RecentCustomList extends ConsumerWidget {
  const RecentCustomList({required this.onSelect, super.key});

  static const caption = 'RECENTLY ADDED BY YOU';

  final ValueChanged<String> onSelect;

  static String periodLabel(Subscription subscription) =>
      switch (subscription.period) {
        BillingPeriod.weekly => 'Weekly',
        BillingPeriod.monthly => 'Monthly',
        BillingPeriod.quarterly => 'Quarterly',
        BillingPeriod.yearly => 'Yearly',
        BillingPeriod.customDays => 'Every ${subscription.customDays} days',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentCustomSubscriptionsProvider);
    if (recent.isEmpty) return const SizedBox.shrink();
    final lapse = context.lapse;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Space.xxl),
        Text(caption, style: lapse.text.caption),
        const SizedBox(height: Space.md),
        for (final subscription in recent) ...[
          CatalogResultRow(
            key: ValueKey('catalog-recent-${subscription.id}'),
            leading: ServiceTile(
              name: subscription.name,
              size: CatalogResultRow.tileSize,
            ),
            title: subscription.name,
            subtitle: 'Custom · ${periodLabel(subscription)}',
            semanticLabel:
                '${subscription.name}, custom, ${periodLabel(subscription)}',
            onTap: () =>
                onSelect(Routes.newSubscriptionFor(name: subscription.name)),
          ),
          const SizedBox(height: Space.sm),
        ],
      ],
    );
  }
}
