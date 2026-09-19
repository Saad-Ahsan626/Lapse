import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/validation/subscription_field.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_state.dart';

class BillingCycleSection extends StatelessWidget {
  const BillingCycleSection({
    required this.state,
    required this.customDaysController,
    required this.onPeriodChanged,
    required this.onCustomDaysChanged,
    super.key,
  });

  final SubscriptionFormState state;
  final TextEditingController customDaysController;
  final ValueChanged<BillingPeriod> onPeriodChanged;
  final ValueChanged<String> onCustomDaysChanged;

  static String labelOf(BillingPeriod period) => switch (period) {
    BillingPeriod.weekly => 'Weekly',
    BillingPeriod.monthly => 'Monthly',
    BillingPeriod.quarterly => 'Quarterly',
    BillingPeriod.yearly => 'Yearly',
    BillingPeriod.customDays => 'Custom',
  };

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final custom = state.period == BillingPeriod.customDays;

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
            for (final period in BillingPeriod.values)
              LapseChip(
                label: labelOf(period),
                selected: state.period == period,
                onTap: () => onPeriodChanged(period),
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
                      errorText: state.errors[SubscriptionField.customDays],
                      onChanged: onCustomDaysChanged,
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
