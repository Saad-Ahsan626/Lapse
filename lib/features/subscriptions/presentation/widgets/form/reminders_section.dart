import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/domain/validation/subscription_field.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_state.dart';

class RemindersSection extends StatelessWidget {
  const RemindersSection({
    required this.state,
    required this.onToggle,
    super.key,
  });

  static const offsets = [7, 3, 1, 0];

  final SubscriptionFormState state;
  final ValueChanged<int> onToggle;

  static String labelOf(int offset) => switch (offset) {
    0 => 'Same day',
    1 => '1 day',
    _ => '$offset days',
  };

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    final error = state.errors[SubscriptionField.reminderOffsets];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: Text('REMIND ME', style: lapse.text.caption)),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: Space.sm,
          children: [
            for (final offset in offsets)
              LapseChip(
                label: labelOf(offset),
                selected: state.reminderOffsets.contains(offset),
                showCheck: true,
                compact: true,
                onTap: () => onToggle(offset),
              ),
          ],
        ),
        if (error != null)
          Text(error, style: lapse.text.meta.copyWith(color: c.urgentText)),
      ],
    );
  }
}
