import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/form/reminders_section.dart';

Future<List<int>?> showDefaultRemindersSheet(
  BuildContext context,
  List<int> selected,
) => showLapseSheet<List<int>>(
  context: context,
  title: 'Default reminders',
  builder: (_) => DefaultRemindersSheet(initial: selected),
);

class DefaultRemindersSheet extends StatefulWidget {
  const DefaultRemindersSheet({required this.initial, super.key});

  final List<int> initial;

  static const note =
      'Applies to new subscriptions. Existing ones keep their own reminders.';

  @override
  State<DefaultRemindersSheet> createState() => _DefaultRemindersSheetState();
}

class _DefaultRemindersSheetState extends State<DefaultRemindersSheet> {
  late final Set<int> _selected = {...widget.initial};

  void _toggle(int offset) => setState(() {
    if (!_selected.remove(offset)) _selected.add(offset);
  });

  void _save() {
    final offsets = _selected.toList()..sort((a, b) => b.compareTo(a));
    Navigator.of(context).pop(offsets);
  }

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        0,
        Space.screen,
        Space.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Remind me before each charge',
            style: lapse.text.bodyMuted,
          ),
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: Space.sm,
            children: [
              for (final offset in RemindersSection.offsets)
                LapseChip(
                  label: RemindersSection.labelOf(offset),
                  selected: _selected.contains(offset),
                  showCheck: true,
                  onTap: () => _toggle(offset),
                ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Text(DefaultRemindersSheet.note, style: lapse.text.meta),
          const SizedBox(height: Space.xl),
          LapseButton(label: 'Save', expand: true, onPressed: _save),
        ],
      ),
    );
  }
}
