import '../features/home/home_harness.dart';
import 'a11y_data.dart';
import 'a11y_test_support.dart';

void main() {
  accessibilityTests('home empty', (tester, brightness, scale) async {
    await pumpHome(tester, brightness: brightness, textScale: scale);
  });

  accessibilityTests('home with data', (tester, brightness, scale) async {
    await pumpHome(
      tester,
      subscriptions: homeSubscriptions(),
      brightness: brightness,
      textScale: scale,
    );
  });
}
