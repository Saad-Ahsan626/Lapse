import 'package:lapse/core/database/schema.dart';
import 'package:sqflite/sqflite.dart';

class SubscriptionLocalDataSource {
  const SubscriptionLocalDataSource(this._db);

  static const _maxVariables = 500;

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

  Future<Map<String, String>> nextBillingDates(List<String> ids) async {
    final result = <String, String>{};
    for (var start = 0; start < ids.length; start += _maxVariables) {
      final end = start + _maxVariables < ids.length
          ? start + _maxVariables
          : ids.length;
      final chunk = ids.sublist(start, end);
      final rows = await _db.query(
        Tables.subscriptions,
        columns: ['id', 'next_billing_date'],
        where: 'id IN (${List.filled(chunk.length, '?').join(', ')})',
        whereArgs: chunk,
      );
      for (final row in rows) {
        result[row['id']! as String] = row['next_billing_date']! as String;
      }
    }
    return result;
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

  Future<List<Map<String, Object?>>> allCharges() => _db.query(
    Tables.charges,
    orderBy: 'subscription_id ASC, charged_on ASC, id ASC',
  );

  Future<List<Map<String, Object?>>> chargesBetween(String from, String to) =>
      _db.query(
        Tables.charges,
        where: 'charged_on BETWEEN ? AND ?',
        whereArgs: [from, to],
        orderBy: 'charged_on ASC, id ASC',
      );

  Future<void> insertCharges(List<Map<String, Object?>> rows) async {
    if (rows.isEmpty) return;
    final batch = _db.batch();
    for (final row in rows) {
      batch.insert(Tables.charges, row);
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteEverything() async {
    await _db.delete(Tables.charges);
    await _db.delete(Tables.subscriptions);
  }
}
