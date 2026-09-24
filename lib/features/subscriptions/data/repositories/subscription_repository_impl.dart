import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:lapse/core/database/schema.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/subscriptions/data/datasources/subscription_local_data_source.dart';
import 'package:lapse/features/subscriptions/data/mappers/charge_mapper.dart';
import 'package:lapse/features/subscriptions/data/mappers/subscription_mapper.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/repositories/roll_over_write.dart';
import 'package:lapse/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:sqflite/sqflite.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl(this._db);

  final Database _db;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  SubscriptionLocalDataSource get _source => SubscriptionLocalDataSource(_db);

  @override
  Stream<List<Subscription>> watchAll() =>
      _watch(getAll, listEquals<Subscription>);

  @override
  Stream<Subscription?> watchById(String id) =>
      _watch(() => getById(id), (a, b) => a == b);

  @override
  Future<void> refresh() async => _notify();

  @override
  Future<List<Subscription>> getAll() async {
    final rows = await _source.subscriptions();
    return rows.map(SubscriptionMapper.fromRow).toList();
  }

  @override
  Future<Subscription?> getById(String id) async {
    final row = await _source.subscription(id);
    return row == null ? null : SubscriptionMapper.fromRow(row);
  }

  @override
  Future<void> upsert(Subscription subscription) async {
    await _source.upsertSubscription(SubscriptionMapper.toRow(subscription));
    _notify();
  }

  @override
  Future<void> delete(String id) async {
    await _source.deleteSubscription(id);
    _notify();
  }

  @override
  Future<List<Charge>> chargesFor(String subscriptionId) async {
    final rows = await _source.charges(subscriptionId);
    return rows.map(ChargeMapper.fromRow).toList();
  }

  @override
  Future<List<Charge>> allCharges() async {
    final rows = await _source.allCharges();
    return rows.map(ChargeMapper.fromRow).toList();
  }

  @override
  Future<List<Charge>> chargesBetween(
    CalendarDate from,
    CalendarDate to,
  ) async {
    final rows = await _source.chargesBetween(from.toIso(), to.toIso());
    return rows.map(ChargeMapper.fromRow).toList();
  }

  @override
  Future<bool> applyRollOver(
    Subscription updated,
    List<Charge> charges, {
    CalendarDate? expectedNextBillingDate,
  }) async {
    final applied = await _applyOne(updated, charges, expectedNextBillingDate);
    if (applied) _notify();
    return applied;
  }

  @override
  Future<int> applyRollOvers(List<RollOverWrite> writes) async {
    if (writes.isEmpty) return 0;
    int applied;
    try {
      applied = await _applyBatch(writes);
    } on Object {
      applied = await _applyEach(writes);
    }
    if (applied > 0) _notify();
    return applied;
  }

  @override
  Future<void> replaceAll(
    List<Subscription> subscriptions,
    List<Charge> charges,
  ) async {
    await _db.transaction((txn) async {
      await SubscriptionLocalDataSource(txn).deleteEverything();
      final batch = txn.batch();
      for (final subscription in subscriptions) {
        batch.insert(
          Tables.subscriptions,
          SubscriptionMapper.toRow(subscription),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final charge in charges) {
        batch.insert(Tables.charges, ChargeMapper.toRow(charge));
      }
      await batch.commit(noResult: true);
    });
    _notify();
  }

  Future<void> dispose() => _changes.close();

  Future<bool> _applyOne(
    Subscription updated,
    List<Charge> charges,
    CalendarDate? expectedNextBillingDate,
  ) => _db.transaction((txn) async {
    final source = SubscriptionLocalDataSource(txn);
    if (expectedNextBillingDate != null) {
      final current = await source.subscription(updated.id);
      if (current == null ||
          current['next_billing_date'] != expectedNextBillingDate.toIso()) {
        return false;
      }
    }
    await source.upsertSubscription(SubscriptionMapper.toRow(updated));
    await source.insertCharges(charges.map(ChargeMapper.toRow).toList());
    return true;
  });

  Future<int> _applyBatch(List<RollOverWrite> writes) =>
      _db.transaction((txn) async {
        final current = await SubscriptionLocalDataSource(
          txn,
        ).nextBillingDates([for (final write in writes) write.$1.id]);
        final batch = txn.batch();
        var applied = 0;
        for (final (updated, charges, expectedNext) in writes) {
          if (current[updated.id] != expectedNext.toIso()) continue;
          batch.update(
            Tables.subscriptions,
            SubscriptionMapper.toRow(updated),
            where: 'id = ?',
            whereArgs: [updated.id],
          );
          for (final charge in charges) {
            batch.insert(Tables.charges, ChargeMapper.toRow(charge));
          }
          current[updated.id] = updated.nextBillingDate.toIso();
          applied++;
        }
        await batch.commit(noResult: true);
        return applied;
      });

  Future<int> _applyEach(List<RollOverWrite> writes) async {
    var applied = 0;
    for (final (updated, charges, expectedNext) in writes) {
      try {
        if (await _applyOne(updated, charges, expectedNext)) applied++;
      } on Object {
        continue;
      }
    }
    return applied;
  }

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Stream<T> _watch<T>(
    Future<T> Function() query,
    bool Function(T a, T b) same,
  ) {
    late final StreamController<T> controller;
    StreamSubscription<void>? changes;
    var pending = Future<void>.value();
    var hasLast = false;
    T? last;

    void refresh() {
      pending = pending.then((_) async {
        if (controller.isClosed) return;
        try {
          final value = await query();
          if (controller.isClosed) return;
          if (hasLast && same(last as T, value)) return;
          hasLast = true;
          last = value;
          controller.add(value);
        } on Object catch (error, stackTrace) {
          if (controller.isClosed) return;
          hasLast = false;
          last = null;
          controller.addError(error, stackTrace);
        }
      });
    }

    controller = StreamController<T>(
      onListen: () {
        changes = _changes.stream.listen((_) => refresh());
        refresh();
      },
      onCancel: () async {
        await changes?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }
}
