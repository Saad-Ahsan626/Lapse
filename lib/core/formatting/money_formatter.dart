import 'package:intl/intl.dart';
import 'package:lapse/core/domain/currency_info.dart';
import 'package:lapse/core/domain/money.dart';

final _grouping = NumberFormat.decimalPattern('en');
final _inputPattern = RegExp(r'^(\d*)(?:\.(\d*))?$');
final _letterEnd = RegExp(r'[A-Za-z]$');
final _whitespace = RegExp(r'\s');

String formatMoney(Money money, {bool showCode = false}) {
  final symbol = currencyInfo(money.currency).symbol;
  final separator = _letterEnd.hasMatch(symbol) ? ' ' : '';
  final sign = money.minor < 0 ? '-' : '';
  final amount = _amountText(money, grouped: true);
  final code = showCode ? ' ${money.currency}' : '';
  return '$sign$symbol$separator$amount$code';
}

String moneyInputText(Money money) {
  final sign = money.minor < 0 ? '-' : '';
  return '$sign${_amountText(money, grouped: false)}';
}

Money? parseMoneyInput(String text, String currency) {
  final digits = Money.fractionDigits(currency);
  final cleaned = _normalizeSeparators(text, digits);
  final match = _inputPattern.firstMatch(cleaned);
  if (match == null) return null;
  final whole = match.group(1)!;
  final fraction = match.group(2);
  if (whole.isEmpty && (fraction == null || fraction.isEmpty)) return null;
  if (fraction != null && (digits == 0 || fraction.length > digits)) {
    return null;
  }
  final wholeValue = whole.isEmpty ? 0 : int.tryParse(whole);
  if (wholeValue == null) return null;
  final padded = (fraction ?? '').padRight(digits, '0');
  final fractionValue = padded.isEmpty ? 0 : int.parse(padded);
  return Money(wholeValue * _scale(digits) + fractionValue, currency);
}

String _normalizeSeparators(String text, int digits) {
  final compact = text.replaceAll(_whitespace, '');
  final lastComma = compact.lastIndexOf(',');
  if (lastComma < 0) return compact;
  final singleComma = compact.indexOf(',') == lastComma;
  final lastDot = compact.lastIndexOf('.');
  if (lastDot > lastComma || !singleComma) {
    return compact.replaceAll(',', '');
  }
  final before = compact.substring(0, lastComma);
  final after = compact.substring(lastComma + 1);
  if (lastDot >= 0) return '${before.replaceAll('.', '')}.$after';
  if (after.isNotEmpty && after.length <= digits && after.length != 3) {
    return '$before.$after';
  }
  return '$before$after';
}

String _amountText(Money money, {required bool grouped}) {
  final digits = Money.fractionDigits(money.currency);
  final scale = _scale(digits);
  final absolute = money.minor.abs();
  final whole = absolute ~/ scale;
  final fraction = absolute % scale;
  final wholeText = grouped ? _grouping.format(whole) : '$whole';
  if (fraction == 0) return wholeText;
  return '$wholeText.${fraction.toString().padLeft(digits, '0')}';
}

int _scale(int digits) {
  var scale = 1;
  for (var i = 0; i < digits; i++) {
    scale *= 10;
  }
  return scale;
}
