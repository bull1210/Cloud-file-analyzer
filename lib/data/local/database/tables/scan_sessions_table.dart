import 'package:drift/drift.dart';

class ScanSessionsTable extends Table {
  @override
  String get tableName => 'scan_sessions';

  TextColumn get id => text()();
  TextColumn get accountId => text()();
  IntColumn get startedAt => integer()();
  IntColumn get completedAt => integer().nullable()();
  TextColumn get status => text()();
  IntColumn get totalFiles => integer().withDefault(const Constant(0))();
  IntColumn get totalFolders => integer().withDefault(const Constant(0))();
  IntColumn get totalBytes => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
