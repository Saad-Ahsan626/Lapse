import 'package:lapse/core/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> openTestDatabase() {
  sqfliteFfiInit();
  return openAppDatabase(
    factory: databaseFactoryFfi,
    path: inMemoryDatabasePath,
  );
}
