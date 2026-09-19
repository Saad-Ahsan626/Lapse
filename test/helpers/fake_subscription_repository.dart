import 'dart:async';

import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/repositories/subscription_repository.dart';

class FakeSubscriptionRepository implements SubscriptionRepository {
  final Map<String, Subscription> subscriptions = {};
  final List<Charge> charges = [];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  void seed(Iterable<Subscription> items) {
    for (final item in items) {
      subscriptions[item.id] = item;
    }
  }

  @override
  Stream<List<Subscription>> watchAll() async* {
    yield await getAll();
    await for (final _ in _changes.stream) {
      yield await getAll();
    }
  }

  @override
  Stream<Subscription?> watchById(String id) async* {
    yield subscriptions[id];
    await for (final _ in _changes.stream) {
      yield subscriptions[id];
    }
  }

  @override
  Future<List<Subscription>> getAll() async => subscriptions.values.toList();

  @override
  Future<Subscription?> getById(String id) async => subscriptions[id];

  @override
  Future<void> upsert(Subscription subscription) async {
    subscriptions[subscription.id] = subscription;
    _changes.add(null);
  }

  @override
  Future<void> delete(String id) async {
    subscriptions.remove(id);
    charges.removeWhere((c) => c.subscriptionId == id);
    _changes.add(null);
  }

  @override
  Future<List<Charge>> chargesFor(String subscriptionId) async =>
      charges.where((c) => c.subscriptionId == subscriptionId).toList();

  @override
  Future<void> applyRollOver(Subscription updated, List<Charge> added) async {
    subscriptions[updated.id] = updated;
    charges.addAll(added);
    _changes.add(null);
  }

  @override
  Future<void> replaceAll(
    List<Subscription> items,
    List<Charge> newCharges,
  ) async {
    subscriptions
      ..clear()
      ..addEntries(items.map((s) => MapEntry(s.id, s)));
    charges
      ..clear()
      ..addAll(newCharges);
    _changes.add(null);
  }
}
