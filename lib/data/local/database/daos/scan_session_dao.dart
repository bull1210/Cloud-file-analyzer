import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/scan_sessions_table.dart';

part 'scan_session_dao.g.dart';

@DriftAccessor(tables: [ScanSessionsTable])
class ScanSessionDao extends DatabaseAccessor<AppDatabase>
    with _$ScanSessionDaoMixin {
  ScanSessionDao(super.db);

  Future<void> insertSession(ScanSessionsTableCompanion session) =>
      into(scanSessionsTable).insert(session);

  Future<void> updateSession(ScanSessionsTableCompanion session) =>
      (update(scanSessionsTable)
            ..where((t) => t.id.equals(session.id.value)))
          .write(session);

  Future<ScanSessionsTableData?> getLatestSession(String accountId) =>
      (select(scanSessionsTable)
            ..where((t) => t.accountId.equals(accountId))
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<ScanSessionsTableData?> getRunningSessions(String accountId) =>
      (select(scanSessionsTable)
            ..where((t) =>
                t.accountId.equals(accountId) & t.status.equals('running')))
          .getSingleOrNull();

  Future<void> markComplete({
    required String sessionId,
    required int totalFiles,
    required int totalFolders,
    required int totalBytes,
  }) =>
      (update(scanSessionsTable)..where((t) => t.id.equals(sessionId))).write(
        ScanSessionsTableCompanion(
          status: const Value('complete'),
          completedAt: Value(DateTime.now().millisecondsSinceEpoch),
          totalFiles: Value(totalFiles),
          totalFolders: Value(totalFolders),
          totalBytes: Value(totalBytes),
        ),
      );

  Future<void> markFailed({required String sessionId, required String error}) =>
      (update(scanSessionsTable)..where((t) => t.id.equals(sessionId))).write(
        ScanSessionsTableCompanion(
          status: const Value('failed'),
          completedAt: Value(DateTime.now().millisecondsSinceEpoch),
          errorMessage: Value(error),
        ),
      );

  Future<void> markCancelled(String sessionId) =>
      (update(scanSessionsTable)..where((t) => t.id.equals(sessionId))).write(
        ScanSessionsTableCompanion(
          status: const Value('cancelled'),
          completedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
}
