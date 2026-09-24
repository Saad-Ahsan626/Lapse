import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/database/app_database.dart';
import 'package:lapse/core/database/schema.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/reminders/data/sqlite_reminder_plan_store.dart';
import 'package:lapse/features/subscriptions/data/mappers/charge_mapper.dart';
import 'package:lapse/features/subscriptions/data/mappers/subscription_mapper.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/subscription_fixtures.dart';

void main() {
  late Directory directory;
  late String path;

  setUpAll(sqfliteFfiInit);

  setUp(() {
    directory = Directory.systemTemp.createTempSync('lapse_db_');
    path = p.join(directory.path, 'lapse.db');
  });

  tearDown(() async {
    await databaseFactoryFfi.deleteDatabase(path);
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  test('a second app open shares the same connection', () async {
    final main = await openAppDatabase(factory: databaseFactoryFfi, path: path);
    final again = await openAppDatabase(
      factory: databaseFactoryFfi,
      path: path,
    );
    expect(identical(main, again), isTrue);
    await main.close();
  });

  test('closing the background database keeps the app one open', () async {
    final main = await openAppDatabase(factory: databaseFactoryFfi, path: path);
    final background = await openBackgroundDatabase(
      factory: databaseFactoryFfi,
      path: path,
    );
    expect(identical(main, background), isFalse);

    await background.insert(
      Tables.subscriptions,
      SubscriptionMapper.toRow(subscriptionFixture(id: 'bg')),
    );
    await background.close();

    expect(main.isOpen, isTrue);
    final rows = await main.query(Tables.subscriptions);
    expect(rows.map((r) => r['id']), ['bg']);
    await main.close();
  });

  test('a fresh database is created at the latest version', () async {
    final db = await openAppDatabase(factory: databaseFactoryFfi, path: path);
    expect(await db.getVersion(), schemaVersion);
    expect(await _names(db), containsAll(_v2Objects));
    await db.close();
  });

  test('upgrading from v1 to v2 keeps the data', () async {
    final v1 = await openAppDatabase(
      factory: databaseFactoryFfi,
      path: path,
      version: 1,
    );
    expect(await _names(v1), isNot(contains('reminder_plan')));
    await v1.insert(
      Tables.subscriptions,
      SubscriptionMapper.toRow(subscriptionFixture()),
    );
    await v1.insert(
      Tables.charges,
      ChargeMapper.toRow(
        Charge(
          id: 'c1',
          subscriptionId: 'sub-1',
          amount: const Money(29900, 'PKR'),
          chargedOn: CalendarDate(2026, 9, 1),
        ),
      ),
    );
    await v1.close();

    final v2 = await openAppDatabase(factory: databaseFactoryFfi, path: path);

    expect(await v2.getVersion(), 2);
    expect(await _names(v2), containsAll(_v2Objects));
    expect(
      (await v2.query(Tables.subscriptions)).map((r) => r['id']),
      ['sub-1'],
    );
    expect((await v2.query(Tables.charges)).map((r) => r['id']), ['c1']);
    final plan = await v2.rawQuery(
      'EXPLAIN QUERY PLAN SELECT * FROM charges WHERE charged_on > ?',
      ['2026-01-01'],
    );
    expect(
      plan.map((row) => row['detail']).join(' '),
      contains('idx_charges_charged_on'),
    );
    await v2.close();
  });

  test('the reminder plan table round-trips through the store', () async {
    final db = await openAppDatabase(factory: databaseFactoryFfi, path: path);
    final store = SqliteReminderPlanStore(db);

    await store.save({1: 'a', 2: 'b'});
    expect(await store.load(), {1: 'a', 2: 'b'});
    await store.save({2: 'c'});
    expect(await store.load(), {2: 'c'});
    await store.clear();
    expect(await store.load(), isEmpty);
    await db.close();
  });
}

const _v2Objects = [
  'subscriptions',
  'charges',
  'reminder_plan',
  'idx_subscriptions_next',
  'idx_charges_subscription',
  'idx_charges_charged_on',
];

Future<Set<Object?>> _names(Database db) async => (await db.rawQuery(
  "SELECT name FROM sqlite_master WHERE type IN ('table', 'index')",
)).map((row) => row['name']).toSet();
