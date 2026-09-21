import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/onboarding/presentation/widgets/reminder_time_field.dart';

import '../../helpers/pump_app.dart';

class _Host extends StatefulWidget {
  const _Host({required this.initial, required this.changes});

  final int initial;
  final List<int> changes;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late int _minutes = widget.initial;

  @override
  Widget build(BuildContext context) => ReminderTimeField(
    minutes: _minutes,
    onChanged: (value) {
      widget.changes.add(value);
      setState(() => _minutes = value);
    },
  );
}

Future<List<int>> _pump(
  WidgetTester tester, {
  int initial = 540,
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  final changes = <int>[];
  await tester.pumpLapse(
    Padding(
      padding: const EdgeInsets.all(16),
      child: _Host(initial: initial, changes: changes),
    ),
    brightness: brightness,
    textScale: textScale,
  );
  return changes;
}

void main() {
  test('spoken label uses 12-hour time', () {
    expect(ReminderTimeField.spokenLabel(0), '12:00 AM');
    expect(ReminderTimeField.spokenLabel(540), '9:00 AM');
    expect(ReminderTimeField.spokenLabel(720), '12:00 PM');
    expect(ReminderTimeField.spokenLabel(1305), '9:45 PM');
  });

  testWidgets('shows padded 12-hour digits and AM', (tester) async {
    await _pump(tester);

    expect(find.text('09'), findsOneWidget);
    expect(find.text('00'), findsOneWidget);
    expect(find.text('AM'), findsOneWidget);
    expect(find.text('PM'), findsOneWidget);
  });

  testWidgets('afternoon times display as 12-hour digits', (tester) async {
    await _pump(tester, initial: 15 * 60 + 5);
    expect(find.text('03'), findsOneWidget);
    expect(find.text('05'), findsOneWidget);
  });

  testWidgets('has a reminder time semantics label', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);

    expect(find.bySemanticsLabel('Reminder time, 9:00 AM'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('PM adds 12 hours and AM takes them back', (tester) async {
    final changes = await _pump(tester);

    await tester.tap(find.text('AM'));
    await tester.pump();
    expect(changes, isEmpty);

    await tester.tap(find.text('PM'));
    await tester.pumpAndSettle();
    expect(changes, [21 * 60]);
    expect(find.text('09'), findsOneWidget);

    await tester.tap(find.text('AM'));
    await tester.pumpAndSettle();
    expect(changes, [21 * 60, 9 * 60]);
  });

  testWidgets('tapping a box opens the time picker and saves its value', (
    tester,
  ) async {
    final changes = await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('reminder-time-minute')));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);

    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(TimePickerDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), '7');
    await tester.enterText(fields.at(1), '30');
    await tester.tap(find.text('PM').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(changes, [19 * 60 + 30]);
    expect(find.text('07'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
  });

  testWidgets('cancelling the picker keeps the time', (tester) async {
    final changes = await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('reminder-time-hour')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(changes, isEmpty);
  });

  for (final brightness in Brightness.values) {
    testWidgets('text scale 2 in ${brightness.name} does not overflow', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pump(tester, brightness: brightness, textScale: 2);

      expect(tester.takeException(), isNull);
      expect(find.text('PM'), findsOneWidget);
    });
  }
}
