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

final todayProvider = Provider<CalendarDate>(
  (ref) => CalendarDate.fromDateTime(ref.watch(clockProvider)()),
);

final newIdProvider = Provider<IdGenerator>((ref) {
  const uuid = Uuid();
  return uuid.v4;
});
