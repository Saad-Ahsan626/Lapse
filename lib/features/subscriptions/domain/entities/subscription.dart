import 'package:flutter/foundation.dart';

import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';

const Object _unset = Object();

@immutable
class Subscription {
  Subscription({
    required this.id,
    required this.name,
    required this.price,
    required this.period,
    required this.anchorDay,
    required this.startDate,
    required this.nextBillingDate,
    required this.createdAt,
    required this.updatedAt,
    this.catalogKey,
    this.category,
    this.customDays,
    this.isTrial = false,
    List<int> reminderOffsets = const [],
    this.cancelUrl,
    this.paymentMethod,
    this.notes,
    this.status = SubscriptionStatus.active,
    this.cancelledAt,
    this.snoozedUntil,
  }) : reminderOffsets = List.unmodifiable(reminderOffsets);

  static const unsavedId = '';

  final String id;
  final String name;
  final String? catalogKey;
  final String? category;
  final Money price;
  final BillingPeriod period;
  final int? customDays;
  final int anchorDay;
  final CalendarDate startDate;
  final CalendarDate nextBillingDate;
  final bool isTrial;
  final List<int> reminderOffsets;
  final String? cancelUrl;
  final String? paymentMethod;
  final String? notes;
  final SubscriptionStatus status;
  final DateTime? cancelledAt;
  final DateTime? snoozedUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isUnsaved => id == unsavedId;

  bool get isActive => status == SubscriptionStatus.active;

  bool get isCancelled => status == SubscriptionStatus.cancelled;

  Subscription copyWith({
    String? id,
    String? name,
    Object? catalogKey = _unset,
    Object? category = _unset,
    Money? price,
    BillingPeriod? period,
    Object? customDays = _unset,
    int? anchorDay,
    CalendarDate? startDate,
    CalendarDate? nextBillingDate,
    bool? isTrial,
    List<int>? reminderOffsets,
    Object? cancelUrl = _unset,
    Object? paymentMethod = _unset,
    Object? notes = _unset,
    SubscriptionStatus? status,
    Object? cancelledAt = _unset,
    Object? snoozedUntil = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      catalogKey: identical(catalogKey, _unset)
          ? this.catalogKey
          : catalogKey as String?,
      category: identical(category, _unset)
          ? this.category
          : category as String?,
      price: price ?? this.price,
      period: period ?? this.period,
      customDays: identical(customDays, _unset)
          ? this.customDays
          : customDays as int?,
      anchorDay: anchorDay ?? this.anchorDay,
      startDate: startDate ?? this.startDate,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      isTrial: isTrial ?? this.isTrial,
      reminderOffsets: reminderOffsets ?? this.reminderOffsets,
      cancelUrl: identical(cancelUrl, _unset)
          ? this.cancelUrl
          : cancelUrl as String?,
      paymentMethod: identical(paymentMethod, _unset)
          ? this.paymentMethod
          : paymentMethod as String?,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      status: status ?? this.status,
      cancelledAt: identical(cancelledAt, _unset)
          ? this.cancelledAt
          : cancelledAt as DateTime?,
      snoozedUntil: identical(snoozedUntil, _unset)
          ? this.snoozedUntil
          : snoozedUntil as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Subscription &&
      other.id == id &&
      other.name == name &&
      other.catalogKey == catalogKey &&
      other.category == category &&
      other.price == price &&
      other.period == period &&
      other.customDays == customDays &&
      other.anchorDay == anchorDay &&
      other.startDate == startDate &&
      other.nextBillingDate == nextBillingDate &&
      other.isTrial == isTrial &&
      listEquals(other.reminderOffsets, reminderOffsets) &&
      other.cancelUrl == cancelUrl &&
      other.paymentMethod == paymentMethod &&
      other.notes == notes &&
      other.status == status &&
      other.cancelledAt == cancelledAt &&
      other.snoozedUntil == snoozedUntil &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    catalogKey,
    category,
    price,
    period,
    customDays,
    anchorDay,
    startDate,
    nextBillingDate,
    isTrial,
    Object.hashAll(reminderOffsets),
    cancelUrl,
    paymentMethod,
    notes,
    status,
    cancelledAt,
    snoozedUntil,
    createdAt,
    updatedAt,
  ]);

  @override
  String toString() =>
      'Subscription($name, $price ${period.name}, next $nextBillingDate'
      '${isTrial ? ', trial' : ''}, ${status.name})';
}
