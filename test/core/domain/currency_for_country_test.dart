import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/currency_for_country.dart';

void main() {
  test('maps known countries', () {
    expect(currencyForCountry('PK'), 'PKR');
    expect(currencyForCountry('pk'), 'PKR');
    expect(currencyForCountry('DE'), 'EUR');
    expect(currencyForCountry('JP'), 'JPY');
  });

  test('falls back to USD', () {
    expect(currencyForCountry(null), fallbackCurrency);
    expect(currencyForCountry('ZZ'), fallbackCurrency);
  });
}
