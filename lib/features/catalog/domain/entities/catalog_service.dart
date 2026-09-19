import 'package:flutter/foundation.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';

@immutable
class CatalogService {
  const CatalogService({
    required this.key,
    required this.name,
    required this.category,
    required this.initials,
    required this.brandColor,
    required this.defaultPeriod,
    this.cancelUrl,
    this.popularRank,
    this.aliases = const [],
  });

  factory CatalogService.fromJson(Map<String, Object?> json) {
    final key = _requiredString(json, 'key');
    final aliasesRaw = json['aliases'];
    final List<String> aliases;
    if (aliasesRaw == null) {
      aliases = const [];
    } else if (aliasesRaw is List &&
        aliasesRaw.every((alias) => alias is String)) {
      aliases = List.unmodifiable(aliasesRaw.cast<String>());
    } else {
      throw FormatException('Invalid aliases for "$key"');
    }
    final periodName = _requiredString(json, 'defaultPeriod');
    final period = BillingPeriod.fromStorage(periodName);
    if (period == null) {
      throw FormatException('Unknown period "$periodName" for "$key"');
    }
    final cancelUrl = json['cancelUrl'];
    if (cancelUrl != null && cancelUrl is! String) {
      throw FormatException('Invalid cancelUrl for "$key"');
    }
    final popularRank = json['popularRank'];
    if (popularRank != null && popularRank is! int) {
      throw FormatException('Invalid popularRank for "$key"');
    }
    return CatalogService(
      key: key,
      name: _requiredString(json, 'name'),
      category: _requiredString(json, 'category'),
      initials: _requiredString(json, 'initials'),
      brandColor: _parseColor(_requiredString(json, 'brandColor'), key),
      defaultPeriod: period,
      cancelUrl: cancelUrl as String?,
      popularRank: popularRank as int?,
      aliases: aliases,
    );
  }

  final String key;
  final String name;
  final String category;
  final String initials;
  final int brandColor;
  final BillingPeriod defaultPeriod;
  final String? cancelUrl;
  final int? popularRank;
  final List<String> aliases;

  String get logoAsset => 'assets/logos/$key.svg';

  static final RegExp _colorPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

  static String _requiredString(Map<String, Object?> json, String field) {
    final value = json[field];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    throw FormatException('Missing or invalid "$field"');
  }

  static int _parseColor(String value, String key) {
    if (!_colorPattern.hasMatch(value)) {
      throw FormatException('Invalid brandColor "$value" for "$key"');
    }
    return 0xFF000000 | int.parse(value.substring(1), radix: 16);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CatalogService && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'CatalogService($key, $name)';
}
