import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/accounts_table.dart';
import 'tables/file_records_table.dart';
import 'tables/scan_sessions_table.dart';
import 'daos/account_dao.dart';
import 'daos/file_record_dao.dart';
import 'daos/scan_session_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [AccountsTable, FileRecordsTable, ScanSessionsTable],
  daos: [AccountDao, FileRecordDao, ScanSessionDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createIndexes();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v1 → v2: add content_hash column for hash-based duplicate detection
            await m.addColumn(fileRecordsTable, fileRecordsTable.contentHash);
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_file_records_duplicate '
              'ON file_records (account_id, name, size_bytes, content_hash)',
            );
          }
          if (from < 3) {
            // v2 → v3: purge legacy googlePhotos accounts (provider removed from enum)
            await customStatement(
              "DELETE FROM file_records WHERE account_id IN "
              "(SELECT id FROM accounts WHERE provider = 'googlePhotos')",
            );
            await customStatement(
              "DELETE FROM scan_sessions WHERE account_id IN "
              "(SELECT id FROM accounts WHERE provider = 'googlePhotos')",
            );
            await customStatement(
              "DELETE FROM accounts WHERE provider = 'googlePhotos'",
            );
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA journal_mode = WAL');
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_file_records_account_size '
      'ON file_records (account_id, size_bytes DESC)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_file_records_account_category '
      'ON file_records (account_id, category)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_file_records_account_accessed '
      'ON file_records (account_id, accessed_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_file_records_parent '
      'ON file_records (parent_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_file_records_name_size '
      'ON file_records (name, size_bytes)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_file_records_duplicate '
      'ON file_records (account_id, name, size_bytes, content_hash)',
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'cloudvault_db');
  }
}
