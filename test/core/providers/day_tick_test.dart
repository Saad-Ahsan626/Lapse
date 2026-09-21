import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/providers/clock_providers.dart';

import '../../helpers/test_clock.dart';

void main() {
  test('bumping the day tick recomputes today from the clock', () {
    final clock = TestClock(DateTime(2026, 9, 19, 23));
    final container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(clock.call)],
    );
    addTearDown(container.dispose);
    container.listen(todayProvider, (_, _) {});

    expect(container.read(todayProvider), CalendarDate(2026, 9, 19));
    expect(container.read(dayTickProvider), 0);

    clock.advance(const Duration(hours: 2));
    expect(container.read(todayProvider), CalendarDate(2026, 9, 19));

    container.read(dayTickProvider.notifier).bump();

    expect(container.read(dayTickProvider), 1);
    expect(container.read(todayProvider), CalendarDate(2026, 9, 20));
  });

  testWidgets('the day tick bumps itself at local midnight', (tester) async {
    final clock = TestClock(DateTime(2026, 9, 19, 23));
    final container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(clock.call)],
    )..listen(todayProvider, (_, _) {});

    await tester.pump(const Duration(minutes: 30));
    expect(container.read(dayTickProvider), 0);

    clock.advance(const Duration(hours: 1, seconds: 1));
    await tester.pump(const Duration(minutes: 30, seconds: 1));

    expect(container.read(dayTickProvider), 1);
    expect(container.read(todayProvider), CalendarDate(2026, 9, 20));

    clock.advance(const Duration(days: 1));
    await tester.pump(const Duration(days: 1));

    expect(container.read(dayTickProvider), 2);
    container.dispose();
  });
}
