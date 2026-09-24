import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';

typedef MergedBackup = ({
  List<Subscription> subscriptions,
  List<Charge> charges,
});

abstract final class BackupMerge {
  static MergedBackup merge({
    required List<Subscription> local,
    required List<Charge> localCharges,
    required List<Subscription> incoming,
    required List<Charge> incomingCharges,
  }) {
    final byId = <String, Subscription>{
      for (final subscription in local) subscription.id: subscription,
    };
    for (final candidate in incoming) {
      final existing = byId[candidate.id];
      if (existing == null || candidate.updatedAt.isAfter(existing.updatedAt)) {
        byId[candidate.id] = candidate;
      }
    }
    final chargeIds = <String>{};
    final chargeDays = <(String, CalendarDate)>{};
    final charges = <Charge>[];
    for (final charge in [...localCharges, ...incomingCharges]) {
      final day = (charge.subscriptionId, charge.chargedOn);
      if (chargeIds.contains(charge.id) || chargeDays.contains(day)) continue;
      chargeIds.add(charge.id);
      chargeDays.add(day);
      charges.add(charge);
    }
    return (subscriptions: byId.values.toList(), charges: charges);
  }
}
