import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/repositories/roll_over_write.dart';

abstract interface class SubscriptionRepository {
  Stream<List<Subscription>> watchAll();

  Stream<Subscription?> watchById(String id);

  Future<void> refresh();

  Future<List<Subscription>> getAll();

  Future<Subscription?> getById(String id);

  Future<void> upsert(Subscription subscription);

  Future<void> delete(String id);

  Future<List<Charge>> chargesFor(String subscriptionId);

  Future<List<Charge>> allCharges();

  Future<List<Charge>> chargesBetween(CalendarDate from, CalendarDate to);

  Future<bool> applyRollOver(
    Subscription updated,
    List<Charge> charges, {
    CalendarDate? expectedNextBillingDate,
  });

  Future<int> applyRollOvers(List<RollOverWrite> writes);

  Future<void> replaceAll(
    List<Subscription> subscriptions,
    List<Charge> charges,
  );
}
