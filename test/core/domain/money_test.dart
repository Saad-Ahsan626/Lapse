import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/money.dart';

void main() {
  const pkr = Money(29900, 'PKR');

  test('arithmetic keeps the currency', () {
    expect(pkr + const Money(100, 'PKR'), const Money(30000, 'PKR'));
    expect(pkr - const Money(900, 'PKR'), const Money(29000, 'PKR'));
    expect(pkr * 12, const Money(358800, 'PKR'));
  });

  test('refuses to mix currencies', () {
    expect(() => pkr + const Money(1, 'USD'), throwsArgumentError);
    expect(() => pkr - const Money(1, 'USD'), throwsArgumentError);
  });

  test('scaled and dividedBy round to whole minor units', () {
    expect(const Money(101, 'PKR').scaled(0.5), const Money(51, 'PKR'));
    expect(const Money(1000, 'PKR').scaled(365 / 45), const Money(8111, 'PKR'));
    expect(const Money(1000, 'PKR').dividedBy(3), const Money(333, 'PKR'));
    expect(const Money(1001, 'PKR').dividedBy(2), const Money(501, 'PKR'));
  });

  test('zero and sign helpers', () {
    expect(const Money.zero('PKR').isZero, isTrue);
    expect(const Money.zero('PKR').isPositive, isFalse);
    expect(pkr.isPositive, isTrue);
    expect(pkr.isZero, isFalse);
  });

  test('fraction digits', () {
    expect(Money.fractionDigits('PKR'), 2);
    expect(Money.fractionDigits('USD'), 2);
    expect(Money.fractionDigits('JPY'), 0);
    expect(Money.fractionDigits('krw'), 0);
  });

  test('equality, hashCode, toString', () {
    expect(const Money(29900, 'PKR'), pkr);
    expect(const Money(29900, 'PKR').hashCode, pkr.hashCode);
    expect(pkr == const Money(29900, 'USD'), isFalse);
    expect(pkr.toString(), 'Money(29900 PKR)');
  });
}
