import 'package:drift/drift.dart';

class FileRecordsTable extends Table {
  @override
  String get tableName => 'file_records';

  TextColumn get id => text()();
  TextColumn get accountId => text()();
  TextColumn get provider => text()();
  TextColumn get name => text()();
  TextColumn get path => text()();
  IntColumn get sizeBytes => integer().nullable()();
  TextColumn get mimeType => text()();
  TextColumn get category => text()();
  BoolColumn get isFolder => boolean().withDefault(const Constant(false))();
  IntColumn get modifiedAt => integer()();
  IntColumn get accessedAt => integer().nullable()();
  TextColumn get parentId => text().nullable()();
  TextColumn get providerFileId => text()();
  // Algorithm-prefixed content hash for exact-match duplicate detection.
  // Format: "md5:<hex>", "sha1:<hex>", "sha256:<hex>", "quickxor:<base64>".
  // NULL for Google-native formats and OneDrive folders.
  TextColumn get contentHash => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
