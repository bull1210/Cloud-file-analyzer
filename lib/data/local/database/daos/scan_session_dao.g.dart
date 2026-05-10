// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_session_dao.dart';

// ignore_for_file: type=lint
mixin _$ScanSessionDaoMixin on DatabaseAccessor<AppDatabase> {
  $ScanSessionsTableTable get scanSessionsTable =>
      attachedDatabase.scanSessionsTable;
  ScanSessionDaoManager get managers => ScanSessionDaoManager(this);
}

class ScanSessionDaoManager {
  final _$ScanSessionDaoMixin _db;
  ScanSessionDaoManager(this._db);
  $$ScanSessionsTableTableTableManager get scanSessionsTable =>
      $$ScanSessionsTableTableTableManager(
          _db.attachedDatabase, _db.scanSessionsTable);
}
