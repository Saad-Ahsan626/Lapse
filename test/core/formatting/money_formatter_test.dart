import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/core/formatting/money_formatter.dart';

void main() {
  group('formatMoney', () {
    test('groups thousands', () {
      expect(formatMoney(const Money(432000, 'PKR')), 'Rs 4,320');
      expect(formatMoney(const Money(5184000, 'PKR')), 'Rs 51,840');
      expect(formatMoney(const Money(123456789, 'USD')), r'$1,234,567.89');
    });

    test('whole amounts drop decimals', () {
      expect(formatMoney(const Money(64900, 'PKR')), 'Rs 649');
      expect(formatMoney(const Money(500, 'GBP')), '£5');
      expect(formatMoney(const Money(0, 'USD')), r'$0');
    });

    test('other amounts show every decimal', () {
      expect(formatMoney(const Money(699, 'USD')), r'$6.99');
      expect(formatMoney(const Money(650, 'USD')), r'$6.50');
      expect(formatMoney(const Money(5, 'USD')), r'$0.05');
      expect(formatMoney(const Money(3675, 'AED')), 'AED 36.75');
      expect(formatMoney(const Money(1299, 'CAD')), r'CA$12.99');
    });

    test('symbol spacing', () {
      expect(formatMoney(const Money(19900, 'INR')), '₹199');
      expect(formatMoney(const Money(1000, 'MYR')), 'RM 10');
      expect(formatMoney(const Money(1000, 'BRL')), r'R$10');
      expect(formatMoney(const Money(1000, 'XYZ')), 'XYZ 10');
    });

    test('zero-decimal currencies never show decimals', () {
      expect(formatMoney(const Money(980, 'JPY')), '¥980');
      expect(formatMoney(const Money(12000, 'KRW')), '₩12,000');
    });

    test('negative amounts put the sign first', () {
      expect(formatMoney(const Money(-64900, 'PKR')), '-Rs 649');
      expect(formatMoney(const Money(-699, 'USD')), r'-$6.99');
    });

    test('showCode appends the code', () {
      expect(
        formatMoney(const Money(64900, 'PKR'), showCode: true),
        'Rs 649 PKR',
      );
      expect(
        formatMoney(const Money(699, 'USD'), showCode: true),
        r'$6.99 USD',
      );
    });
  });

  group('parseMoneyInput', () {
    test('plain and decimal values', () {
      expect(parseMoneyInput('649', 'PKR'), const Money(64900, 'PKR'));
      expect(parseMoneyInput('6.99', 'USD'), const Money(699, 'USD'));
      expect(parseMoneyInput('6.5', 'USD'), const Money(650, 'USD'));
      expect(parseMoneyInput('.5', 'USD'), const Money(50, 'USD'));
      expect(parseMoneyInput('5.', 'USD'), const Money(500, 'USD'));
      expect(parseMoneyInput('0', 'PKR'), const Money(0, 'PKR'));
    });

    test('commas and spaces are ignored', () {
      expect(parseMoneyInput('1,299', 'PKR'), const Money(129900, 'PKR'));
      expect(
        parseMoneyInput('  1 299.50 ', 'PKR'),
        const Money(129950, 'PKR'),
      );
    });

    test('zero-decimal currencies', () {
      expect(parseMoneyInput('980', 'JPY'), const Money(980, 'JPY'));
      expect(parseMoneyInput('9.5', 'JPY'), isNull);
      expect(parseMoneyInput('980.', 'JPY'), isNull);
    });

    test('invalid input is null', () {
      expect(parseMoneyInput('', 'PKR'), isNull);
      expect(parseMoneyInput('   ', 'PKR'), isNull);
      expect(parseMoneyInput('.', 'PKR'), isNull);
      expect(parseMoneyInput('abc', 'PKR'), isNull);
      expect(parseMoneyInput('12a', 'PKR'), isNull);
      expect(parseMoneyInput('1.2.3', 'PKR'), isNull);
      expect(parseMoneyInput('6.999', 'USD'), isNull);
      expect(parseMoneyInput('-5', 'USD'), isNull);
      expect(parseMoneyInput('99999999999999999999999', 'USD'), isNull);
    });
  });

  group('moneyInputText', () {
    test('prefills without grouping or symbols', () {
      expect(moneyInputText(const Money(64900, 'PKR')), '649');
      expect(moneyInputText(const Money(699, 'USD')), '6.99');
      expect(moneyInputText(const Money(12345, 'PKR')), '123.45');
      expect(moneyInputText(const Money(650, 'USD')), '6.50');
      expect(moneyInputText(const Money(129900, 'PKR')), '1299');
      expect(moneyInputText(const Money(980, 'JPY')), '980');
      expect(moneyInputText(const Money(-699, 'USD')), '-6.99');
    });

    test('round-trips through the parser', () {
      const money = Money(12345, 'PKR');
      expect(parseMoneyInput(moneyInputText(money), 'PKR'), money);
    });
  });
}
