import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';

abstract final class SubscriptionMapper {
  static Map<String, Object?> toRow(Subscription s) => {
    'id': s.id,
    'name': s.name,
    'catalog_key': s.catalogKey,
    'category': s.category,
    'price_minor': s.price.minor,
    'currency': s.price.currency,
    'period': s.period.name,
    'custom_days': s.customDays,
    'anchor_day': s.anchorDay,
    'start_date': s.startDate.toIso(),
    'next_billing_date': s.nextBillingDate.toIso(),
    'is_trial': s.isTrial ? 1 : 0,
    'reminder_offsets': s.reminderOffsets.join(','),
    'cancel_url': s.cancelUrl,
    'payment_method': s.paymentMethod,
    'notes': s.notes,
    'status': s.status.name,
    'cancelled_at': _timestamp(s.cancelledAt),
    'snoozed_until': _timestamp(s.snoozedUntil),
    'created_at': _timestamp(s.createdAt),
    'updated_at': _timestamp(s.updatedAt),
  };

  static Subscription fromRow(Map<String, Object?> row) {
    final period = BillingPeriod.fromStorage(row['period']! as String);
    final status = SubscriptionStatus.fromStorage(row['status']! as String);
    if (period == null || status == null) {
      throw FormatException('Unknown period or status', row);
    }
    return Subscription(
      id: row['id']! as String,
      name: row['name']! as String,
      catalogKey: row['catalog_key'] as String?,
      category: row['category'] as String?,
      price: Money(row['price_minor']! as int, row['currency']! as String),
      period: period,
      customDays: row['custom_days'] as int?,
      anchorDay: row['anchor_day']! as int,
      startDate: CalendarDate.parse(row['start_date']! as String),
      nextBillingDate: CalendarDate.parse(row['next_billing_date']! as String),
      isTrial: row['is_trial'] == 1,
      reminderOffsets: _offsets(row['reminder_offsets'] as String?),
      cancelUrl: row['cancel_url'] as String?,
      paymentMethod: row['payment_method'] as String?,
      notes: row['notes'] as String?,
      status: status,
      cancelledAt: _parseTimestamp(row['cancelled_at']),
      snoozedUntil: _parseTimestamp(row['snoozed_until']),
      createdAt: _parseTimestamp(row['created_at'])!,
      updatedAt: _parseTimestamp(row['updated_at'])!,
    );
  }

  static String? _timestamp(DateTime? value) =>
      value?.toUtc().toIso8601String();

  static DateTime? _parseTimestamp(Object? value) =>
      value is String ? DateTime.parse(value).toUtc() : null;

  static List<int> _offsets(String? value) => value == null || value.isEmpty
      ? const []
      : value.split(',').map(int.parse).toList();
}
