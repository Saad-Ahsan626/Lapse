import 'dart:math' as math;

import 'package:lapse/core/domain/money.dart';

String plainMoney(Money money) {
  final digits = Money.fractionDigits(money.currency);
  final value = money.minor / math.pow(10, digits);
  return '${money.currency} ${value.toStringAsFixed(digits)}';
}
