import 'dart:convert';

import 'package:lapse/features/reminders/domain/planned_reminder.dart';

String reminderSignature(PlannedReminder reminder, {required bool exact}) =>
    jsonEncode([
      reminder.fireAt.toIso8601String(),
      reminder.title,
      reminder.body,
      reminder.kind.name,
      reminder.hasCancelLink,
      exact,
    ]);
