import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/core/formatting/money_formatter.dart';
import 'package:lapse/features/onboarding/domain/example_price.dart';

void main() {
  test('uses the per-currency example amounts', () {
    expect(exampleTrialPrice('PKR'), const Money(64900, 'PKR'));
    expect(exampleTrialPrice('INR'), const Money(19900, 'INR'));
    expect(exampleTrialPrice('USD'), const Money(999, 'USD'));
    expect(exampleTrialPrice('EUR'), const Money(999, 'EUR'));
    expect(exampleTrialPrice('GBP'), const Money(899, 'GBP'));
    expect(exampleTrialPrice('AED'), const Money(3699, 'AED'));
    expect(exampleTrialPrice('SAR'), const Money(3699, 'SAR'));
  });

  test('falls back to 9.99 in any other currency', () {
    expect(exampleTrialPrice('CAD'), const Money(999, 'CAD'));
    expect(exampleTrialPrice('jpy'), const Money(10, 'JPY'));
  });

  test('formats like the design', () {
    expect(formatMoney(exampleTrialPrice('PKR')), 'Rs 649');
    expect(formatMoney(exampleTrialPrice('USD')), r'$9.99');
    expect(formatMoney(exampleTrialPrice('GBP')), '£8.99');
    expect(formatMoney(exampleTrialPrice('AED')), 'AED 36.99');
  });
}
