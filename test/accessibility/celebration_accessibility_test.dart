import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/savings/presentation/widgets/celebration_sheet.dart';

import '../helpers/pump_app.dart';
import 'a11y_test_support.dart';

void main() {
  accessibilityTests('celebration sheet', (tester, brightness, scale) async {
    usePhone(tester);
    await tester.pumpLapse(
      const CelebrationSheet(
        headline: 'iCloud+ 200GB cancelled',
        saved: Money(778800, 'PKR'),
        body: 'It stays in the Cancelled tab in case you want it back.',
        playConfetti: false,
      ),
      brightness: brightness,
      textScale: scale,
    );
    await frames(tester, 20);
  });
}
