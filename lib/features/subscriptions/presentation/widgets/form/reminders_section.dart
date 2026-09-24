import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/domain/validation/subscription_field.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_args.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_controller.dart';

class RemindersSection extends ConsumerWidget {
  const RemindersSection({
    required this.args,
    super.key,
  });

  static const offsets = [7, 3, 1, 0];

  final SubscriptionFormArgs args;

  static String labelOf(int offset) => switch (offset) {
    0 => 'Same day',
    1 => '1 day',
    _ => '$offset days',
  };

  static int _selectedMask(List<int> selected) {
    var mask = 0;
    for (var i = 0; i < offsets.length; i++) {
      if (selected.contains(offsets[i])) mask |= 1 << i;
    }
    return mask;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = subscriptionFormProvider(args);
    final (:mask, :error) = ref.watch(
      provider.select(
        (s) => (
          mask: _selectedMask(s.reminderOffsets),
          error: s.errors[SubscriptionField.reminderOffsets],
        ),
      ),
    );
    final notifier = ref.read(provider.notifier);
    final lapse = context.lapse;
    final c = lapse.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: Text('REMIND ME', style: lapse.text.caption)),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: Space.sm,
          children: [
            for (var i = 0; i < offsets.length; i++)
              LapseChip(
                label: labelOf(offsets[i]),
                selected: mask & (1 << i) != 0,
                showCheck: true,
                compact: true,
                onTap: () => notifier.toggleReminder(offsets[i]),
              ),
          ],
        ),
        if (error != null)
          Text(error, style: lapse.text.meta.copyWith(color: c.urgentText)),
      ],
    );
  }
}
