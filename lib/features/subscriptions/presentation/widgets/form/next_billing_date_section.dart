import 'package:flutter/material.dart';

import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/formatting/date_labels.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/domain/validation/subscription_field.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_state.dart';

class NextBillingDateSection extends StatelessWidget {
  const NextBillingDateSection({
    required this.state,
    required this.today,
    required this.onChanged,
    super.key,
  });

  final SubscriptionFormState state;
  final CalendarDate today;
  final ValueChanged<CalendarDate> onChanged;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    final label = state.isTrial ? 'Trial ends' : 'Next billing date';
    final date = state.nextBillingDate;

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
      firstDate: state.isEdit ? state.startDate : today,
      trailing: trailing,
      errorText: state.errors[SubscriptionField.nextBillingDate],
      onChanged: onChanged,
    );
  }
}
