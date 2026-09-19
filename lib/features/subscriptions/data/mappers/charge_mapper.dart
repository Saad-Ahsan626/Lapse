import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';

abstract final class ChargeMapper {
  static Map<String, Object?> toRow(Charge charge) => {
    'id': charge.id,
    'subscription_id': charge.subscriptionId,
    'amount_minor': charge.amount.minor,
    'currency': charge.amount.currency,
    'charged_on': charge.chargedOn.toIso(),
  };

  static Charge fromRow(Map<String, Object?> row) => Charge(
    id: row['id']! as String,
    subscriptionId: row['subscription_id']! as String,
    amount: Money(row['amount_minor']! as int, row['currency']! as String),
    chargedOn: CalendarDate.parse(row['charged_on']! as String),
  );
}
