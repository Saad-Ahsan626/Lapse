import 'package:flutter/foundation.dart';

@immutable
class CurrencyInfo {
  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
  });

  final String code;
  final String symbol;
  final String name;

  @override
  bool operator ==(Object other) => other is CurrencyInfo && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'CurrencyInfo($code, $symbol, $name)';
}

const List<CurrencyInfo> supportedCurrencies = [
  CurrencyInfo(code: 'PKR', symbol: 'Rs', name: 'Pakistani rupee'),
  CurrencyInfo(code: 'USD', symbol: r'$', name: 'US dollar'),
  CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro'),
  CurrencyInfo(code: 'GBP', symbol: '£', name: 'British pound'),
  CurrencyInfo(code: 'INR', symbol: '₹', name: 'Indian rupee'),
  CurrencyInfo(code: 'AED', symbol: 'AED', name: 'UAE dirham'),
  CurrencyInfo(code: 'SAR', symbol: 'SAR', name: 'Saudi riyal'),
  CurrencyInfo(code: 'CAD', symbol: r'CA$', name: 'Canadian dollar'),
  CurrencyInfo(code: 'AUD', symbol: r'A$', name: 'Australian dollar'),
  CurrencyInfo(code: 'BDT', symbol: '৳', name: 'Bangladeshi taka'),
  CurrencyInfo(code: 'LKR', symbol: 'LKR', name: 'Sri Lankan rupee'),
  CurrencyInfo(code: 'NPR', symbol: 'NPR', name: 'Nepalese rupee'),
  CurrencyInfo(code: 'QAR', symbol: 'QAR', name: 'Qatari riyal'),
  CurrencyInfo(code: 'KWD', symbol: 'KWD', name: 'Kuwaiti dinar'),
  CurrencyInfo(code: 'OMR', symbol: 'OMR', name: 'Omani rial'),
  CurrencyInfo(code: 'BHD', symbol: 'BHD', name: 'Bahraini dinar'),
  CurrencyInfo(code: 'TRY', symbol: '₺', name: 'Turkish lira'),
  CurrencyInfo(code: 'EGP', symbol: 'E£', name: 'Egyptian pound'),
  CurrencyInfo(code: 'NGN', symbol: '₦', name: 'Nigerian naira'),
  CurrencyInfo(code: 'KES', symbol: 'KSh', name: 'Kenyan shilling'),
  CurrencyInfo(code: 'ZAR', symbol: 'R', name: 'South African rand'),
  CurrencyInfo(code: 'JPY', symbol: '¥', name: 'Japanese yen'),
  CurrencyInfo(code: 'KRW', symbol: '₩', name: 'South Korean won'),
  CurrencyInfo(code: 'CNY', symbol: '¥', name: 'Chinese yuan'),
  CurrencyInfo(code: 'SGD', symbol: r'S$', name: 'Singapore dollar'),
  CurrencyInfo(code: 'MYR', symbol: 'RM', name: 'Malaysian ringgit'),
  CurrencyInfo(code: 'IDR', symbol: 'Rp', name: 'Indonesian rupiah'),
  CurrencyInfo(code: 'PHP', symbol: '₱', name: 'Philippine peso'),
  CurrencyInfo(code: 'THB', symbol: '฿', name: 'Thai baht'),
  CurrencyInfo(code: 'CHF', symbol: 'CHF', name: 'Swiss franc'),
  CurrencyInfo(code: 'SEK', symbol: 'kr', name: 'Swedish krona'),
  CurrencyInfo(code: 'NOK', symbol: 'kr', name: 'Norwegian krone'),
  CurrencyInfo(code: 'BRL', symbol: r'R$', name: 'Brazilian real'),
  CurrencyInfo(code: 'MXN', symbol: r'MX$', name: 'Mexican peso'),
];

CurrencyInfo currencyInfo(String code) {
  final upper = code.trim().toUpperCase();
  for (final info in supportedCurrencies) {
    if (info.code == upper) return info;
  }
  return CurrencyInfo(code: upper, symbol: upper, name: upper);
}
