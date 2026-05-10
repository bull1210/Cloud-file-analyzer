// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_record_dao.dart';

// ignore_for_file: type=lint
mixin _$FileRecordDaoMixin on DatabaseAccessor<AppDatabase> {
  $FileRecordsTableTable get fileRecordsTable =>
      attachedDatabase.fileRecordsTable;
  FileRecordDaoManager get managers => FileRecordDaoManager(this);
}

class FileRecordDaoManager {
  final _$FileRecordDaoMixin _db;
  FileRecordDaoManager(this._db);
  $$FileRecordsTableTableTableManager get fileRecordsTable =>
      $$FileRecordsTableTableTableManager(
          _db.attachedDatabase, _db.fileRecordsTable);
}
