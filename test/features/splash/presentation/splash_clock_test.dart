import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/splash/presentation/splash_clock.dart';

void main() {
  Duration ms(int value) => Duration(milliseconds: value);

  test('the first tick only anchors the clock', () {
    final clock = SplashClock(duration: ms(600));

    expect(clock.tick(ms(5000)), 0);
    expect(clock.elapsed, Duration.zero);
    expect(clock.isDone, isFalse);
  });

  test('advances with the ticker on smooth frames', () {
    final clock = SplashClock(duration: ms(600))
      ..tick(Duration.zero)
      ..tick(ms(16))
      ..tick(ms(32));

    expect(clock.elapsed, ms(32));
    expect(clock.progress, closeTo(32 / 600, 1e-9));
  });

  test('caps a stalled frame at 32 ms', () {
    final clock = SplashClock(duration: ms(2100))
      ..tick(Duration.zero)
      ..tick(ms(16))
      ..tick(ms(916));

    expect(clock.elapsed, ms(48));
    expect(SplashClock.defaultMaxStep, ms(32));
  });

  test('ignores a ticker that moves backwards', () {
    final clock = SplashClock(duration: ms(600))
      ..tick(ms(100))
      ..tick(ms(50));

    expect(clock.elapsed, Duration.zero);
  });

  test('stops at the full duration', () {
    final clock = SplashClock(duration: ms(64))..tick(Duration.zero);

    for (var i = 1; i <= 10; i++) {
      clock.tick(ms(i * 16));
    }

    expect(clock.elapsed, ms(64));
    expect(clock.progress, 1);
    expect(clock.isDone, isTrue);
  });

  test('a zero duration is done at once', () {
    expect(SplashClock(duration: Duration.zero).isDone, isTrue);
  });
}
