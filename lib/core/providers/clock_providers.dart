import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/clock.dart';
import 'package:uuid/uuid.dart';

final clockOffsetProvider = NotifierProvider<ClockOffsetController, Duration>(
  ClockOffsetController.new,
);

class ClockOffsetController extends Notifier<Duration> {
  @override
  Duration build() => Duration.zero;

  void travel(Duration by) => state += by;

  void reset() => state = Duration.zero;
}

final clockProvider = Provider<Clock>((ref) {
  final offset = ref.watch(clockOffsetProvider);
  return () => DateTime.now().add(offset);
});

final dayTickProvider = NotifierProvider<DayTick, int>(DayTick.new);

class DayTick extends Notifier<int> {
  static const _midnightSlack = Duration(seconds: 1);

  Timer? _timer;
  Clock? _clock;

  @override
  int build() {
    _clock = ref.watch(clockProvider);
    ref.onDispose(_cancel);
    _scheduleMidnight();
    return 0;
  }

  void bump() {
    state++;
    _scheduleMidnight();
  }

  void _scheduleMidnight() {
    _cancel();
    final clock = _clock;
    if (clock == null) return;
    final now = clock();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(midnight.difference(now) + _midnightSlack, bump);
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

final todayProvider = Provider<CalendarDate>((ref) {
  ref.watch(dayTickProvider);
  return CalendarDate.fromDateTime(ref.watch(clockProvider)());
});

final newIdProvider = Provider<IdGenerator>((ref) {
  const uuid = Uuid();
  return uuid.v4;
});
