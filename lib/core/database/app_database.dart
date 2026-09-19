import 'package:lapse/core/database/migrations.dart';
import 'package:lapse/core/database/schema.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

Future<Database> openAppDatabase({
  DatabaseFactory? factory,
  String? path,
}) async {
  final dbFactory = factory ?? databaseFactory;
  final dbPath =
      path ?? p.join(await dbFactory.getDatabasesPath(), databaseFileName);

  return dbFactory.openDatabase(
    dbPath,
    options: OpenDatabaseOptions(
      version: schemaVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        for (final statement in schemaV1) {
          await db.execute(statement);
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        for (var version = oldVersion + 1; version <= newVersion; version++) {
          for (final statement in migrations[version] ?? const <String>[]) {
            await db.execute(statement);
          }
        }
      },
    ),
  );
}
