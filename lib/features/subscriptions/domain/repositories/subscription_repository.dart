import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';

abstract interface class SubscriptionRepository {
  Stream<List<Subscription>> watchAll();

  Stream<Subscription?> watchById(String id);

  Future<List<Subscription>> getAll();

  Future<Subscription?> getById(String id);

  Future<void> upsert(Subscription subscription);

  Future<void> delete(String id);

  Future<List<Charge>> chargesFor(String subscriptionId);

  Future<List<Charge>> chargesBetween(CalendarDate from, CalendarDate to);

  Future<void> applyRollOver(Subscription updated, List<Charge> charges);

  Future<void> replaceAll(
    List<Subscription> subscriptions,
    List<Charge> charges,
  );
}
