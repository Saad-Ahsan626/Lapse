import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/repositories/roll_over_write.dart';
import 'package:lapse/features/subscriptions/domain/repositories/subscription_repository.dart';

class FakeSubscriptionRepository implements SubscriptionRepository {
  final Map<String, Subscription> subscriptions = {};
  final List<Charge> charges = [];
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int refreshCount = 0;

  void seed(Iterable<Subscription> items) {
    for (final item in items) {
      subscriptions[item.id] = item;
    }
  }

  @override
  Stream<List<Subscription>> watchAll() => _watch(
    () => subscriptions.values.toList(),
    listEquals<Subscription>,
  );

  @override
  Stream<Subscription?> watchById(String id) =>
      _watch(() => subscriptions[id], (a, b) => a == b);

  @override
  Future<void> refresh() async {
    refreshCount++;
    _notify();
  }

  @override
  Future<List<Subscription>> getAll() async => subscriptions.values.toList();

  @override
  Future<Subscription?> getById(String id) async => subscriptions[id];

  @override
  Future<void> upsert(Subscription subscription) async {
    subscriptions[subscription.id] = subscription;
    _notify();
  }

  @override
  Future<void> delete(String id) async {
    subscriptions.remove(id);
    charges.removeWhere((c) => c.subscriptionId == id);
    _notify();
  }

  @override
  Future<List<Charge>> chargesFor(String subscriptionId) async =>
      charges.where((c) => c.subscriptionId == subscriptionId).toList();

  @override
  Future<List<Charge>> allCharges() async => [...charges]
    ..sort((a, b) {
      final bySubscription = a.subscriptionId.compareTo(b.subscriptionId);
      if (bySubscription != 0) return bySubscription;
      return a.chargedOn.compareTo(b.chargedOn);
    });

  @override
  Future<List<Charge>> chargesBetween(
    CalendarDate from,
    CalendarDate to,
  ) async =>
      charges
          .where((c) => !c.chargedOn.isBefore(from) && !c.chargedOn.isAfter(to))
          .toList()
        ..sort((a, b) => a.chargedOn.compareTo(b.chargedOn));

  @override
  Future<bool> applyRollOver(
    Subscription updated,
    List<Charge> added, {
    CalendarDate? expectedNextBillingDate,
  }) async {
    final applied = _applyOne(updated, added, expectedNextBillingDate);
    if (applied) _notify();
    return applied;
  }

  @override
  Future<int> applyRollOvers(List<RollOverWrite> writes) async {
    var applied = 0;
    for (final (updated, added, expectedNext) in writes) {
      if (_applyOne(updated, added, expectedNext)) applied++;
    }
    if (applied > 0) _notify();
    return applied;
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
    _notify();
  }

  bool _applyOne(
    Subscription updated,
    List<Charge> added,
    CalendarDate? expectedNextBillingDate,
  ) {
    final current = subscriptions[updated.id];
    if (expectedNextBillingDate != null &&
        current?.nextBillingDate != expectedNextBillingDate) {
      return false;
    }
    subscriptions[updated.id] = updated;
    charges.addAll(added);
    return true;
  }

  void _notify() => _changes.add(null);

  Stream<T> _watch<T>(T Function() read, bool Function(T a, T b) same) {
    late final StreamController<T> controller;
    StreamSubscription<void>? changes;
    late T last;
    controller = StreamController<T>(
      onListen: () {
        last = read();
        controller.add(last);
        changes = _changes.stream.listen((_) {
          final next = read();
          if (same(last, next)) return;
          last = next;
          controller.add(next);
        });
      },
      onCancel: () => changes?.cancel(),
    );
    return controller.stream;
  }
}
