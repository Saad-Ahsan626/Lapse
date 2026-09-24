import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/core/formatting/date_labels.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/domain/validation/subscription_field.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_args.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_controller.dart';

class NextBillingDateSection extends ConsumerWidget {
  const NextBillingDateSection({
    required this.args,
    super.key,
  });

  final SubscriptionFormArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = subscriptionFormProvider(args);
    final (:isTrial, :isEdit, :startDate, :date, :error) = ref.watch(
      provider.select(
        (s) => (
          isTrial: s.isTrial,
          isEdit: s.isEdit,
          startDate: s.startDate,
          date: s.nextBillingDate,
          error: s.errors[SubscriptionField.nextBillingDate],
        ),
      ),
    );
    final today = ref.watch(todayProvider);
    final lapse = context.lapse;
    final c = lapse.colors;
    final label = isTrial ? 'Trial ends' : 'Next billing date';

    Widget? trailing;
    if (date != null) {
      final days = today.daysUntil(date);
      final color = days <= 1
          ? c.urgentText
          : days <= 3
          ? c.warningText
          : c.inkSubtle;
      trailing = Text(
        relativeDueLabel(date, today),
        style: lapse.text.body.copyWith(
          color: color,
          fontWeight: days <= 1 ? FontWeight.w700 : FontWeight.w600,
        ),
      );
    }

    return LapseDateField(
      label: label,
      value: date,
      format: fullDateLabel,
      firstDate: isEdit ? startDate : today,
      trailing: trailing,
      errorText: error,
      onChanged: ref.read(provider.notifier).setNextBillingDate,
    );
  }
}
