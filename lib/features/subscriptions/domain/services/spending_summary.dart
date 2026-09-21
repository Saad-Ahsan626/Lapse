import 'package:flutter/foundation.dart';
import 'package:lapse/core/domain/money.dart';

@immutable
class SpendingSummary {
  const SpendingSummary({
    required this.thisMonth,
    required this.yearly,
    required this.savedPerYear,
    this.otherCurrencies = const {},
  });

  factory SpendingSummary.zero(String currency) => SpendingSummary(
    thisMonth: Money.zero(currency),
    yearly: Money.zero(currency),
    savedPerYear: Money.zero(currency),
  );

  final Money thisMonth;
  final Money yearly;
  final Money savedPerYear;
  final Map<String, Money> otherCurrencies;

  bool get hasSavings => savedPerYear.isPositive;

  @override
  bool operator ==(Object other) =>
      other is SpendingSummary &&
      other.thisMonth == thisMonth &&
      other.yearly == yearly &&
      other.savedPerYear == savedPerYear &&
      mapEquals(other.otherCurrencies, otherCurrencies);

  @override
  int get hashCode => Object.hash(
    thisMonth,
    yearly,
    savedPerYear,
    Object.hashAllUnordered(
      otherCurrencies.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  String toString() =>
      'SpendingSummary(month $thisMonth, year $yearly, '
      'saved $savedPerYear, other $otherCurrencies)';
}
