import 'dart:async';

import 'package:lapse/features/subscriptions/data/datasources/subscription_local_data_source.dart';
import 'package:lapse/features/subscriptions/data/mappers/charge_mapper.dart';
import 'package:lapse/features/subscriptions/data/mappers/subscription_mapper.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:sqflite/sqflite.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl(this._db);

  final Database _db;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  SubscriptionLocalDataSource get _source => SubscriptionLocalDataSource(_db);

  @override
  Stream<List<Subscription>> watchAll() => _watch(getAll);

  @override
  Stream<Subscription?> watchById(String id) => _watch(() => getById(id));

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
  Future<void> applyRollOver(Subscription updated, List<Charge> charges) async {
    await _db.transaction((txn) async {
      final source = SubscriptionLocalDataSource(txn);
      await source.upsertSubscription(SubscriptionMapper.toRow(updated));
      await source.insertCharges(charges.map(ChargeMapper.toRow).toList());
    });
    _notify();
  }

  @override
  Future<void> replaceAll(
    List<Subscription> subscriptions,
    List<Charge> charges,
  ) async {
    await _db.transaction((txn) async {
      final source = SubscriptionLocalDataSource(txn);
      await source.deleteEverything();
      for (final subscription in subscriptions) {
        await source.upsertSubscription(SubscriptionMapper.toRow(subscription));
      }
      await source.insertCharges(charges.map(ChargeMapper.toRow).toList());
    });
    _notify();
  }

  Future<void> dispose() => _changes.close();

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Stream<T> _watch<T>(Future<T> Function() query) {
    late final StreamController<T> controller;
    StreamSubscription<void>? changes;
    var pending = Future<void>.value();

    void refresh() {
      pending = pending.then((_) async {
        if (controller.isClosed) return;
        try {
          final value = await query();
          if (!controller.isClosed) controller.add(value);
        } on Object catch (error, stackTrace) {
          if (!controller.isClosed) controller.addError(error, stackTrace);
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
