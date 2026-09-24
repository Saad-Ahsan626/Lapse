import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/validation/subscription_field.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_args.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_controller.dart';

class BillingCycleSection extends ConsumerWidget {
  const BillingCycleSection({
    required this.args,
    required this.customDaysController,
    super.key,
  });

  final SubscriptionFormArgs args;
  final TextEditingController customDaysController;

  static String labelOf(BillingPeriod period) => switch (period) {
    BillingPeriod.weekly => 'Weekly',
    BillingPeriod.monthly => 'Monthly',
    BillingPeriod.quarterly => 'Quarterly',
    BillingPeriod.yearly => 'Yearly',
    BillingPeriod.customDays => 'Custom',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = subscriptionFormProvider(args);
    final (:period, :error) = ref.watch(
      provider.select(
        (s) =>
            (period: s.period, error: s.errors[SubscriptionField.customDays]),
      ),
    );
    final notifier = ref.read(provider.notifier);
    final lapse = context.lapse;
    final custom = period == BillingPeriod.customDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Text('BILLING CYCLE', style: lapse.text.caption),
        ),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: 9,
          children: [
            for (final option in BillingPeriod.values)
              LapseChip(
                label: labelOf(option),
                selected: period == option,
                onTap: () => notifier.setPeriod(option),
              ),
          ],
        ),
        if (custom) ...[
          const SizedBox(height: Space.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ExcludeSemantics(
                  child: Text('Every', style: lapse.text.body),
                ),
              ),
              const SizedBox(width: Space.md),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Semantics(
                    label: 'Bill every how many days',
                    child: LapseTextField(
                      controller: customDaysController,
                      hint: '30',
                      tabular: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      errorText: error,
                      onChanged: notifier.setCustomDays,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Space.md),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ExcludeSemantics(
                  child: Text('days', style: lapse.text.body),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
