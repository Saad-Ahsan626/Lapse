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
    final chargeIds = {for (final charge in localCharges) charge.id};
    final charges = [
      ...localCharges,
      for (final charge in incomingCharges)
        if (chargeIds.add(charge.id)) charge,
    ];
    return (subscriptions: byId.values.toList(), charges: charges);
  }
}
