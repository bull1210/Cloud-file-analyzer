import 'package:drift/drift.dart';

class AccountsTable extends Table {
  @override
  String get tableName => 'accounts';

  TextColumn get id => text()();
  TextColumn get provider => text()();
  TextColumn get email => text()();
  TextColumn get displayName => text()();
  TextColumn get label => text()();
  IntColumn get createdAt => integer()();
  IntColumn get lastScanAt => integer().nullable()();
  IntColumn get totalFiles => integer().withDefault(const Constant(0))();
  IntColumn get totalFolders => integer().withDefault(const Constant(0))();
  IntColumn get totalBytes => integer().withDefault(const Constant(0))();
  TextColumn get photoUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
