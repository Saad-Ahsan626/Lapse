import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/core/formatting/money_formatter.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/features/savings/domain/cancellation_stats.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_list_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

class SavingsSummaryCard extends ConsumerWidget {
  const SavingsSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptions = ref.watch(subscriptionsProvider).value;
    final currency = ref.watch(
      settingsProvider.select((settings) => settings.defaultCurrency),
    );
    final engine = ref.watch(billingEngineProvider);
    if (subscriptions == null) return const SizedBox.shrink();

    final count = CancellationStats.cancelledCount(subscriptions, currency);
    final saved = CancellationStats.savedPerYear(
      subscriptions,
      currency,
      engine,
    );
    if (count == 0 || !saved.isPositive) return const SizedBox.shrink();

    final c = context.lapse.colors;
    final text = context.lapse.text;
    final amount = formatMoney(saved);
    final from = count == 1
        ? 'from 1 cancellation'
        : 'from $count cancellations';

    return Semantics(
      container: true,
      label: 'Saved $amount per year, $from',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.savingsTint,
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: Space.md,
          ),
          child: Row(
            children: [
              Icon(Icons.savings_outlined, color: c.savings, size: 26),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved $amount / year',
                      style: text.section.copyWith(
                        color: c.savingsText,
                        fontWeight: FontWeight.w800,
                        fontFeatures: LapseTypography.tabular,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      from,
                      style: text.meta.copyWith(color: c.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
