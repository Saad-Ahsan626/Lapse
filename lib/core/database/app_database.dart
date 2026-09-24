import 'package:lapse/core/database/migrations.dart';
import 'package:lapse/core/database/schema.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

Future<Database> openAppDatabase({
  DatabaseFactory? factory,
  String? path,
  bool singleInstance = true,
  int version = schemaVersion,
}) async {
  final dbFactory = factory ?? databaseFactory;
  final dbPath =
      path ?? p.join(await dbFactory.getDatabasesPath(), databaseFileName);

  return dbFactory.openDatabase(
    dbPath,
    options: OpenDatabaseOptions(
      version: version,
      singleInstance: singleInstance,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        for (final statement in schemaV1) {
          await db.execute(statement);
        }
        await _migrate(db, 1, version);
      },
      onUpgrade: _migrate,
    ),
  );
}

Future<Database> openBackgroundDatabase({
  DatabaseFactory? factory,
  String? path,
}) => openAppDatabase(factory: factory, path: path, singleInstance: false);

Future<void> _migrate(Database db, int oldVersion, int newVersion) async {
  for (var version = oldVersion + 1; version <= newVersion; version++) {
    for (final statement in migrations[version] ?? const <String>[]) {
      await db.execute(statement);
    }
  }
}
