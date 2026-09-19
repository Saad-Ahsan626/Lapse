import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/currency_info.dart';

void main() {
  test('PKR comes first and codes are unique', () {
    expect(supportedCurrencies.first.code, 'PKR');
    expect(supportedCurrencies[1].code, 'USD');
    final codes = supportedCurrencies.map((c) => c.code).toSet();
    expect(codes.length, supportedCurrencies.length);
    expect(supportedCurrencies.length, greaterThanOrEqualTo(30));
  });

  test('known currencies have their symbols', () {
    expect(currencyInfo('PKR').symbol, 'Rs');
    expect(currencyInfo('INR').symbol, '₹');
    expect(currencyInfo('USD').symbol, r'$');
    expect(currencyInfo('EUR').symbol, '€');
    expect(currencyInfo('GBP').symbol, '£');
    expect(currencyInfo('JPY').symbol, '¥');
    expect(currencyInfo('CNY').symbol, '¥');
    expect(currencyInfo('KRW').symbol, '₩');
    expect(currencyInfo('CAD').symbol, r'CA$');
    expect(currencyInfo('PKR').name, 'Pakistani rupee');
  });

  test('lookup ignores case', () {
    expect(currencyInfo('usd'), currencyInfo('USD'));
    expect(currencyInfo('eUr').symbol, '€');
  });

  test('unknown codes fall back to the code', () {
    const expected = CurrencyInfo(code: 'XYZ', symbol: 'XYZ', name: 'XYZ');
    final info = currencyInfo('xyz');
    expect(info, expected);
    expect(info.symbol, 'XYZ');
    expect(info.name, 'XYZ');
  });

  test('equality and hash use the code only', () {
    const a = CurrencyInfo(code: 'USD', symbol: r'$', name: 'A');
    const b = CurrencyInfo(code: 'USD', symbol: 'US', name: 'B');
    const c = CurrencyInfo(code: 'CAD', symbol: r'$', name: 'A');
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(c));
    expect(a.toString(), contains('USD'));
  });
}
