import 'package:flutter/foundation.dart';

@immutable
class Money {
  const Money(this.minor, this.currency);

  const Money.zero(this.currency) : minor = 0;

  static const _zeroDecimalCurrencies = {
    'BIF',
    'CLP',
    'DJF',
    'GNF',
    'ISK',
    'JPY',
    'KMF',
    'KRW',
    'PYG',
    'RWF',
    'UGX',
    'VND',
    'VUV',
    'XAF',
    'XOF',
    'XPF',
  };

  static const _threeDecimalCurrencies = {
    'BHD',
    'IQD',
    'JOD',
    'KWD',
    'LYD',
    'OMR',
    'TND',
  };

  final int minor;
  final String currency;

  static int fractionDigits(String currency) {
    final code = currency.toUpperCase();
    if (_zeroDecimalCurrencies.contains(code)) return 0;
    if (_threeDecimalCurrencies.contains(code)) return 3;
    return 2;
  }

  bool get isZero => minor == 0;

  bool get isPositive => minor > 0;

  Money operator +(Money other) {
    _requireSameCurrency(other);
    return Money(minor + other.minor, currency);
  }

  Money operator -(Money other) {
    _requireSameCurrency(other);
    return Money(minor - other.minor, currency);
  }

  Money operator *(int times) => Money(minor * times, currency);

  Money scaled(double factor) => Money((minor * factor).round(), currency);

  Money dividedBy(int parts) => Money((minor / parts).round(), currency);

  void _requireSameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError(
        'Cannot combine $currency with ${other.currency}',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.minor == minor && other.currency == currency;

  @override
  int get hashCode => Object.hash(minor, currency);

  @override
  String toString() => 'Money($minor $currency)';
}
