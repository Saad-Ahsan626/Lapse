import 'dart:convert';

import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/backup/domain/backup_data.dart';
import 'package:lapse/features/backup/domain/backup_format_exception.dart';
import 'package:lapse/features/backup/domain/backup_settings.dart';
import 'package:lapse/features/settings/domain/entities/app_theme_mode.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';

abstract final class BackupCodec {
  static const schemaVersion = 1;
  static const appId = 'lapse';

  static const _encoder = JsonEncoder.withIndent('  ');
  static final _currency = RegExp(r'^[A-Z]{3}$');
  static final _isoDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
  static const int _minutesPerDay = 24 * 60;
  static const _maxReminderOffset = 30;
  static const _byteOrderMark = '\u{FEFF}';

  static String encode(BackupData data) =>
      '${_encoder.convert({
        'app': appId,
        'schemaVersion': schemaVersion,
        'exportedAt': _timestamp(data.exportedAt),
        'settings': _settingsToJson(data.settings),
        'subscriptions': data.subscriptions.map(_subscriptionToJson).toList(),
        'charges': data.charges.map(_chargeToJson).toList(),
      })}\n';

  static BackupData decode(String source) {
    final text = source.startsWith(_byteOrderMark)
        ? source.substring(1)
        : source;
    final Object? root;
    try {
      root = jsonDecode(text);
    } on FormatException {
      throw const BackupFormatException.notJson();
    }
    if (root is! Map<String, Object?> || root['app'] != appId) {
      throw const BackupFormatException.wrongApp();
    }
    final version = root['schemaVersion'];
    if (version is! int || version < 1) {
      throw const BackupFormatException.missingVersion();
    }
    if (version > schemaVersion) {
      throw const BackupFormatException.newerVersion();
    }
    final exportedAt = _tryTimestamp(root['exportedAt']);
    if (exportedAt == null) {
      throw const BackupFormatException.badExportDate();
    }
    final settings = _settingsFromJson(root['settings']);
    final rawSubscriptions = root['subscriptions'];
    final rawCharges = root['charges'];
    if (rawSubscriptions is! List<Object?> || rawCharges is! List<Object?>) {
      throw const BackupFormatException.badList();
    }
    final subscriptions = _subscriptionsFromJson(rawSubscriptions);
    final ids = {for (final s in subscriptions) s.id};
    final charges = _chargesFromJson(rawCharges, ids);
    return BackupData(
      exportedAt: exportedAt,
      settings: settings,
      subscriptions: subscriptions,
      charges: charges,
    );
  }

  static Map<String, Object?> _settingsToJson(BackupSettings s) => {
    'defaultCurrency': s.defaultCurrency,
    'reminderMinutes': s.reminderMinutes,
    'defaultReminderOffsets': s.defaultReminderOffsets,
    'themeMode': s.themeMode.name,
    'userName': s.userName,
  };

  static Map<String, Object?> _subscriptionToJson(Subscription s) => {
    'id': s.id,
    'name': s.name,
    'catalogKey': s.catalogKey,
    'category': s.category,
    'price': _moneyToJson(s.price),
    'period': s.period.name,
    'customDays': s.customDays,
    'anchorDay': s.anchorDay,
    'startDate': s.startDate.toIso(),
    'nextBillingDate': s.nextBillingDate.toIso(),
    'isTrial': s.isTrial,
    'reminderOffsets': s.reminderOffsets,
    'cancelUrl': s.cancelUrl,
    'paymentMethod': s.paymentMethod,
    'notes': s.notes,
    'status': s.status.name,
    'cancelledAt': _optionalTimestamp(s.cancelledAt),
    'snoozedUntil': _optionalTimestamp(s.snoozedUntil),
    'createdAt': _timestamp(s.createdAt),
    'updatedAt': _timestamp(s.updatedAt),
  };

  static Map<String, Object?> _chargeToJson(Charge c) => {
    'id': c.id,
    'subscriptionId': c.subscriptionId,
    'amount': _moneyToJson(c.amount),
    'chargedOn': c.chargedOn.toIso(),
  };

  static Map<String, Object?> _moneyToJson(Money money) => {
    'minor': money.minor,
    'currency': money.currency,
  };

  static String _timestamp(DateTime value) => value.toUtc().toIso8601String();

  static String? _optionalTimestamp(DateTime? value) =>
      value == null ? null : _timestamp(value);

  static BackupSettings _settingsFromJson(Object? json) {
    try {
      final map = _map(json);
      final minutes = _int(map['reminderMinutes']);
      if (minutes < 0 || minutes >= _minutesPerDay) {
        throw const FormatException();
      }
      return BackupSettings(
        defaultCurrency: _currencyCode(map['defaultCurrency']),
        reminderMinutes: minutes,
        defaultReminderOffsets: _offsets(map['defaultReminderOffsets']),
        themeMode: _enum(AppThemeMode.values, map['themeMode']),
        userName: _optionalString(map['userName']),
      );
    } on FormatException {
      throw const BackupFormatException.badSettings();
    }
  }

  static List<Subscription> _subscriptionsFromJson(List<Object?> list) {
    final seen = <String>{};
    final result = <Subscription>[];
    for (var i = 0; i < list.length; i++) {
      final json = list[i];
      final Subscription subscription;
      try {
        subscription = _subscriptionFromJson(json);
      } on FormatException {
        final name = json is Map<String, Object?> ? json['name'] : null;
        throw BackupFormatException.badSubscription(
          name is String ? name : null,
          i + 1,
        );
      }
      if (!seen.add(subscription.id)) {
        throw BackupFormatException.duplicateSubscription(subscription.name);
      }
      result.add(subscription);
    }
    return result;
  }

  static Subscription _subscriptionFromJson(Object? json) {
    final map = _map(json);
    final period = _enum(BillingPeriod.values, map['period']);
    final customDays = _optionalInt(map['customDays']);
    if (period == BillingPeriod.customDays &&
        (customDays == null || customDays < 1)) {
      throw const FormatException();
    }
    final anchorDay = _int(map['anchorDay']);
    if (anchorDay < 1 || anchorDay > 31) throw const FormatException();
    final name = _string(map['name']);
    if (name.trim().isEmpty) throw const FormatException();
    return Subscription(
      id: _id(map['id']),
      name: name,
      catalogKey: _optionalString(map['catalogKey']),
      category: _optionalString(map['category']),
      price: _money(map['price']),
      period: period,
      customDays: customDays,
      anchorDay: anchorDay,
      startDate: _date(map['startDate']),
      nextBillingDate: _date(map['nextBillingDate']),
      isTrial: _bool(map['isTrial']),
      reminderOffsets: _offsets(map['reminderOffsets']),
      cancelUrl: _optionalString(map['cancelUrl']),
      paymentMethod: _optionalString(map['paymentMethod']),
      notes: _optionalString(map['notes']),
      status: _enum(SubscriptionStatus.values, map['status']),
      cancelledAt: _optionalTimestampFromJson(map['cancelledAt']),
      snoozedUntil: _optionalTimestampFromJson(map['snoozedUntil']),
      createdAt: _requiredTimestamp(map['createdAt']),
      updatedAt: _requiredTimestamp(map['updatedAt']),
    );
  }

  static List<Charge> _chargesFromJson(
    List<Object?> list,
    Set<String> subscriptionIds,
  ) {
    final seen = <String>{};
    final result = <Charge>[];
    for (var i = 0; i < list.length; i++) {
      try {
        final map = _map(list[i]);
        final charge = Charge(
          id: _id(map['id']),
          subscriptionId: _id(map['subscriptionId']),
          amount: _money(map['amount']),
          chargedOn: _date(map['chargedOn']),
        );
        if (!subscriptionIds.contains(charge.subscriptionId) ||
            !seen.add(charge.id)) {
          throw const FormatException();
        }
        result.add(charge);
      } on FormatException {
        throw BackupFormatException.badPayment(i + 1);
      }
    }
    return result;
  }

  static Map<String, Object?> _map(Object? json) =>
      json is Map<String, Object?> ? json : throw const FormatException();

  static String _string(Object? json) =>
      json is String ? json : throw const FormatException();

  static String _id(Object? json) {
    final value = _string(json);
    return value.isEmpty ? throw const FormatException() : value;
  }

  static String? _optionalString(Object? json) =>
      json == null ? null : _string(json);

  static int _int(Object? json) =>
      json is int ? json : throw const FormatException();

  static int? _optionalInt(Object? json) => json == null ? null : _int(json);

  static bool _bool(Object? json) =>
      json is bool ? json : throw const FormatException();

  static T _enum<T extends Enum>(List<T> values, Object? json) =>
      values.asNameMap()[_string(json)] ?? (throw const FormatException());

  static String _currencyCode(Object? json) {
    final code = _string(json);
    return _currency.hasMatch(code) ? code : throw const FormatException();
  }

  static Money _money(Object? json) {
    final map = _map(json);
    final minor = _int(map['minor']);
    if (minor < 0) throw const FormatException();
    return Money(minor, _currencyCode(map['currency']));
  }

  static List<int> _offsets(Object? json) {
    if (json is! List<Object?>) throw const FormatException();
    final offsets = json.map(_int).toList();
    if (offsets.any((d) => d < 0 || d > _maxReminderOffset)) {
      throw const FormatException();
    }
    return offsets;
  }

  static CalendarDate _date(Object? json) {
    final match = _isoDate.firstMatch(_string(json));
    if (match == null) throw const FormatException();
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    if (month < 1 || month > 12) throw const FormatException();
    if (day < 1 || day > CalendarDate.daysInMonth(year, month)) {
      throw const FormatException();
    }
    return CalendarDate(year, month, day);
  }

  static DateTime? _tryTimestamp(Object? json) =>
      json is String ? DateTime.tryParse(json)?.toUtc() : null;

  static DateTime _requiredTimestamp(Object? json) =>
      _tryTimestamp(json) ?? (throw const FormatException());

  static DateTime? _optionalTimestampFromJson(Object? json) =>
      json == null ? null : _requiredTimestamp(json);
}
