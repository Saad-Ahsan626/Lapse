import 'package:lapse/core/database/schema.dart';
import 'package:sqflite/sqflite.dart';

class SubscriptionLocalDataSource {
  const SubscriptionLocalDataSource(this._db);

  final DatabaseExecutor _db;

  Future<List<Map<String, Object?>>> subscriptions() => _db.query(
    Tables.subscriptions,
    orderBy: 'next_billing_date ASC, name COLLATE NOCASE ASC',
  );

  Future<Map<String, Object?>?> subscription(String id) async {
    final rows = await _db.query(
      Tables.subscriptions,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> upsertSubscription(Map<String, Object?> row) async {
    final updated = await _db.update(
      Tables.subscriptions,
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
    if (updated == 0) {
      await _db.insert(Tables.subscriptions, row);
    }
  }

  Future<void> deleteSubscription(String id) =>
      _db.delete(Tables.subscriptions, where: 'id = ?', whereArgs: [id]);

  Future<List<Map<String, Object?>>> charges(String subscriptionId) =>
      _db.query(
        Tables.charges,
        where: 'subscription_id = ?',
        whereArgs: [subscriptionId],
        orderBy: 'charged_on ASC',
      );

  Future<void> insertCharges(List<Map<String, Object?>> rows) async {
    for (final row in rows) {
      await _db.insert(Tables.charges, row);
    }
  }

  Future<void> deleteEverything() async {
    await _db.delete(Tables.charges);
    await _db.delete(Tables.subscriptions);
  }
}
