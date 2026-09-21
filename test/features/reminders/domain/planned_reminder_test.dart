import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/reminders/domain/planned_reminder.dart';
import 'package:lapse/features/reminders/domain/reminder_kind.dart';

void main() {
  PlannedReminder reminder({
    int id = 42,
    String subscriptionId = 'sub-1',
    DateTime? fireAt,
    String title = 'Spotify renews tomorrow',
    String body = 'Rs 299 on Thu, 1 Oct. Tap to cancel.',
    ReminderKind kind = ReminderKind.renewal,
    bool hasCancelLink = true,
  }) => PlannedReminder(
    id: id,
    subscriptionId: subscriptionId,
    fireAt: fireAt ?? DateTime(2026, 9, 30, 9),
    title: title,
    body: body,
    kind: kind,
    hasCancelLink: hasCancelLink,
  );

  test('equal when every field matches', () {
    expect(reminder(), reminder());
    expect(reminder().hashCode, reminder().hashCode);
  });

  test('differs when any field differs', () {
    final base = reminder();
    expect(base, isNot(reminder(id: 43)));
    expect(base, isNot(reminder(subscriptionId: 'sub-2')));
    expect(base, isNot(reminder(fireAt: DateTime(2026, 9, 30, 10))));
    expect(base, isNot(reminder(title: 'other')));
    expect(base, isNot(reminder(body: 'other')));
    expect(base, isNot(reminder(kind: ReminderKind.snoozed)));
    expect(base, isNot(reminder(hasCancelLink: false)));
    expect(base == Object(), isFalse);
  });

  test('toString is readable', () {
    expect(reminder().toString(), contains('sub-1'));
    expect(reminder().toString(), contains('renewal'));
    expect(reminder().toString(), contains('cancel link'));
    expect(
      reminder(hasCancelLink: false).toString(),
      isNot(contains('cancel link')),
    );
  });
}
