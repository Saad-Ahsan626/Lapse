import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/settings/presentation/formatting/settings_labels.dart';

void main() {
  test('currencyLabel shows the code and symbol', () {
    expect(currencyLabel('PKR'), 'PKR · Rs');
    expect(currencyLabel('usd'), r'USD · $');
    expect(currencyLabel('AED'), 'AED');
    expect(currencyLabel('XYZ'), 'XYZ');
  });

  test('reminderOffsetsLabel sorts, uses Day of and Off', () {
    expect(reminderOffsetsLabel(const [7, 1]), '7d, 1d');
    expect(reminderOffsetsLabel(const [0, 7, 3]), '7d, 3d, Day of');
    expect(reminderOffsetsLabel(const [1, 1]), '1d');
    expect(reminderOffsetsLabel(const []), 'Off');
  });

  test('reminderTimeLabel pads a 12-hour clock', () {
    expect(reminderTimeLabel(9 * 60), '09:00 AM');
    expect(reminderTimeLabel(0), '12:00 AM');
    expect(reminderTimeLabel(12 * 60 + 5), '12:05 PM');
    expect(reminderTimeLabel(21 * 60 + 30), '09:30 PM');
  });

  test('reminderMomentLabel joins the day and the time', () {
    expect(
      reminderMomentLabel(DateTime(2026, 9, 24, 9)),
      'Thu, 24 Sep · 09:00 AM',
    );
  });
}
