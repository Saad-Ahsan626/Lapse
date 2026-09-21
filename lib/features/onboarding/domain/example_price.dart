import 'package:lapse/core/domain/money.dart';

const Map<String, double> _examplePrices = {
  'PKR': 649,
  'INR': 199,
  'USD': 9.99,
  'EUR': 9.99,
  'GBP': 8.99,
  'AED': 36.99,
  'SAR': 36.99,
};

Money exampleTrialPrice(String currency) {
  final code = currency.trim().toUpperCase();
  final amount = _examplePrices[code] ?? 9.99;
  var scale = 1;
  for (var i = 0; i < Money.fractionDigits(code); i++) {
    scale *= 10;
  }
  return Money((amount * scale).round(), code);
}
