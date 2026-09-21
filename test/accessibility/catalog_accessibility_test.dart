import '../features/catalog/presentation/catalog_picker_harness.dart';
import 'a11y_test_support.dart';

void main() {
  accessibilityTests('catalog sheet', (tester, brightness, scale) async {
    await pumpPickerApp(tester, brightness: brightness, textScale: scale);
    await openPicker(tester);
  });
}
