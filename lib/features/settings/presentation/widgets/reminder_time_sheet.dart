import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/onboarding/presentation/widgets/reminder_time_field.dart';

Future<int?> showReminderTimeSheet(BuildContext context, int minutes) =>
    showLapseSheet<int>(
      context: context,
      title: 'Reminder time',
      builder: (_) => ReminderTimeSheet(initial: minutes),
    );

class ReminderTimeSheet extends StatefulWidget {
  const ReminderTimeSheet({required this.initial, super.key});

  final int initial;

  static const note = 'Every reminder arrives at this time of day.';

  @override
  State<ReminderTimeSheet> createState() => _ReminderTimeSheetState();
}

class _ReminderTimeSheetState extends State<ReminderTimeSheet> {
  late int _minutes = widget.initial;

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
          ReminderTimeField(
            minutes: _minutes,
            onChanged: (value) => setState(() => _minutes = value),
          ),
          const SizedBox(height: Space.md),
          Text(
            ReminderTimeSheet.note,
            textAlign: TextAlign.center,
            style: lapse.text.meta,
          ),
          const SizedBox(height: Space.xl),
          LapseButton(
            label: 'Save',
            expand: true,
            onPressed: () => Navigator.of(context).pop(_minutes),
          ),
        ],
      ),
    );
  }
}
