import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/file_records_table.dart';
import '../../../../core/constants/app_constants.dart';

part 'file_record_dao.g.dart';

@DriftAccessor(tables: [FileRecordsTable])
class FileRecordDao extends DatabaseAccessor<AppDatabase>
    with _$FileRecordDaoMixin {
  FileRecordDao(super.db);

  Future<void> insertBatch(List<FileRecordsTableCompanion> records) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(fileRecordsTable, records);
    });
  }

  Future<void> deleteAllForAccount(String accountId) =>
      (delete(fileRecordsTable)
            ..where((t) => t.accountId.equals(accountId)))
          .go();

  Future<void> deleteByLocalId(String id) =>
      (delete(fileRecordsTable)..where((t) => t.id.equals(id))).go();

  Future<List<FileRecordsTableData>> getFilesForAccount({
    required String accountId,
    int limit = 50,
    int offset = 0,
    String? nameFilter,
    String? categoryFilter,
    bool foldersOnly = false,
    bool filesOnly = false,
    int? minSizeBytes,
    int? maxSizeBytes,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    String sortColumn = 'size_bytes',
    bool sortAsc = false,
  }) {
    var query = select(fileRecordsTable)
      ..where((t) => t.accountId.equals(accountId));

    if (nameFilter != null && nameFilter.isNotEmpty) {
      query = query..where((t) => t.name.like('%$nameFilter%'));
    }
    if (categoryFilter != null) {
      query = query..where((t) => t.category.equals(categoryFilter));
    }
    if (foldersOnly) {
      query = query..where((t) => t.isFolder.equals(true));
    }
    if (filesOnly) {
      query = query..where((t) => t.isFolder.equals(false));
    }
    if (minSizeBytes != null) {
      query = query..where((t) => t.sizeBytes.isBiggerOrEqualValue(minSizeBytes));
    }
    if (maxSizeBytes != null) {
      query = query..where((t) => t.sizeBytes.isSmallerOrEqualValue(maxSizeBytes));
    }
    if (modifiedAfter != null) {
      query = query
        ..where((t) =>
            t.modifiedAt.isBiggerOrEqualValue(modifiedAfter.millisecondsSinceEpoch));
    }
    if (modifiedBefore != null) {
      query = query
        ..where((t) =>
            t.modifiedAt.isSmallerOrEqualValue(modifiedBefore.millisecondsSinceEpoch));
    }

    query = query
      ..orderBy([
        (t) => sortColumn == 'name'
            ? OrderingTerm(expression: t.name, mode: sortAsc ? OrderingMode.asc : OrderingMode.desc)
            : sortColumn == 'modified_at'
                ? OrderingTerm(expression: t.modifiedAt, mode: sortAsc ? OrderingMode.asc : OrderingMode.desc)
                : OrderingTerm(expression: t.sizeBytes, mode: sortAsc ? OrderingMode.asc : OrderingMode.desc),
      ])
      ..limit(limit, offset: offset);

    return query.get();
  }

  Future<List<FileRecordsTableData>> getLargestFiles({
    required String accountId,
    int limit = AppConstants.maxLargestFiles,
  }) {
    return (select(fileRecordsTable)
          ..where((t) => t.accountId.equals(accountId) & t.isFolder.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.sizeBytes)])
          ..limit(limit))
        .get();
  }

  Future<List<FileRecordsTableData>> getChildrenOf({
    required String accountId,
    required String parentId,
  }) {
    return (select(fileRecordsTable)
          ..where((t) =>
              t.accountId.equals(accountId) & t.parentId.equals(parentId)))
        .get();
  }

  Future<List<FileRecordsTableData>> getTopLevelItems(String accountId) {
    return (select(fileRecordsTable)
          ..where((t) =>
              t.accountId.equals(accountId) & t.parentId.isNull()))
        .get();
  }

  Future<Map<String, int>> getCategoryBreakdown(String accountId) async {
    final rows = await customSelect(
      'SELECT category, SUM(size_bytes) as total_bytes, COUNT(*) as file_count '
      'FROM file_records '
      'WHERE account_id = ? AND is_folder = 0 '
      'GROUP BY category',
      variables: [Variable.withString(accountId)],
      readsFrom: {fileRecordsTable},
    ).get();

    return {for (final row in rows) row.read<String>('category'): row.read<int?>('total_bytes') ?? 0};
  }

  Future<List<Map<String, dynamic>>> getCategoryBreakdownFull(String accountId) async {
    final rows = await customSelect(
      'SELECT category, SUM(size_bytes) as total_bytes, COUNT(*) as file_count '
      'FROM file_records '
      'WHERE account_id = ? AND is_folder = 0 '
      'GROUP BY category '
      'ORDER BY total_bytes DESC',
      variables: [Variable.withString(accountId)],
      readsFrom: {fileRecordsTable},
    ).get();

    return rows
        .map((r) => {
              'category': r.read<String>('category'),
              'total_bytes': r.read<int>('total_bytes'),
              'file_count': r.read<int>('file_count'),
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>> getAccessTimeStats(String accountId) async {
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180)).millisecondsSinceEpoch;
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365)).millisecondsSinceEpoch;
    final twoYearsAgo = DateTime.now().subtract(const Duration(days: 730)).millisecondsSinceEpoch;

    final rows = await customSelect(
      '''
      SELECT
        CASE
          WHEN accessed_at >= ? THEN 'recentSixMonths'
          WHEN accessed_at >= ? AND accessed_at < ? THEN 'notAccessedOneYear'
          WHEN accessed_at >= ? AND accessed_at < ? THEN 'notAccessedTwoYears'
          ELSE 'never'
        END as bucket,
        COUNT(*) as file_count,
        SUM(size_bytes) as total_bytes
      FROM file_records
      WHERE account_id = ? AND is_folder = 0
      GROUP BY bucket
      ''',
      variables: [
        Variable.withInt(sixMonthsAgo),
        Variable.withInt(oneYearAgo),
        Variable.withInt(sixMonthsAgo),
        Variable.withInt(twoYearsAgo),
        Variable.withInt(oneYearAgo),
        Variable.withString(accountId),
      ],
      readsFrom: {fileRecordsTable},
    ).get();

    return rows
        .map((r) => {
              'bucket': r.read<String>('bucket'),
              'file_count': r.read<int>('file_count'),
              'total_bytes': r.read<int?>('total_bytes') ?? 0,
            })
        .toList();
  }

  Future<List<FileRecordsTableData>> getFilesByAccessBucket({
    required String accountId,
    required String bucket,
    int limit = 100,
    int offset = 0,
  }) {
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180)).millisecondsSinceEpoch;
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365)).millisecondsSinceEpoch;
    final twoYearsAgo = DateTime.now().subtract(const Duration(days: 730)).millisecondsSinceEpoch;

    var query = select(fileRecordsTable)
      ..where((t) => t.accountId.equals(accountId) & t.isFolder.equals(false));

    switch (bucket) {
      case 'recentSixMonths':
        query = query..where((t) => t.accessedAt.isBiggerOrEqualValue(sixMonthsAgo));
      case 'notAccessedOneYear':
        query = query
          ..where((t) =>
              t.accessedAt.isSmallerThanValue(sixMonthsAgo) &
              t.accessedAt.isBiggerOrEqualValue(oneYearAgo));
      case 'notAccessedTwoYears':
        query = query
          ..where((t) =>
              t.accessedAt.isSmallerThanValue(oneYearAgo) &
              t.accessedAt.isBiggerOrEqualValue(twoYearsAgo));
      default: // 'never'
        query = query
          ..where((t) =>
              t.accessedAt.isNull() |
              t.accessedAt.isSmallerThanValue(twoYearsAgo));
    }

    return (query
          ..orderBy([(t) => OrderingTerm.desc(t.sizeBytes)])
          ..limit(limit, offset: offset))
        .get();
  }

  // Duplicate detection using filename + size + content hash (when available).
  //
  // Grouping key: IFNULL(content_hash, '') — so that:
  //   • Files with the same hash       → definite duplicates (exact match)
  //   • Files with NULL hash           → probable duplicates (name+size match only)
  //   • Files with different hashes    → NOT grouped (excluded from results)
  //
  // No file content is ever downloaded; hashes are retrieved from provider APIs.
  Future<List<Map<String, dynamic>>> findDuplicateSignatures(String accountId) async {
    final rows = await customSelect(
      '''
      SELECT name, size_bytes, content_hash, COUNT(*) as count
      FROM file_records
      WHERE account_id = ? AND is_folder = 0 AND size_bytes > 0
      GROUP BY name, size_bytes, IFNULL(content_hash, '')
      HAVING COUNT(*) > 1
      ORDER BY size_bytes DESC
      ''',
      variables: [Variable.withString(accountId)],
      readsFrom: {fileRecordsTable},
    ).get();

    return rows
        .map((r) => {
              'name': r.read<String>('name'),
              'size_bytes': r.read<int?>('size_bytes') ?? 0,
              'content_hash': r.read<String?>('content_hash'),
              'count': r.read<int>('count'),
            })
        .toList();
  }

  Future<List<FileRecordsTableData>> getFilesWithSignature({
    required String accountId,
    required String name,
    required int sizeBytes,
    String? contentHash,
  }) {
    final query = select(fileRecordsTable)
      ..where((t) =>
          t.accountId.equals(accountId) &
          t.name.equals(name) &
          t.sizeBytes.equals(sizeBytes) &
          t.isFolder.equals(false));

    // When a hash is known, filter to exact hash matches only.
    // When null, fall back to name+size grouping (no hash was available at scan time).
    if (contentHash != null) {
      query.where((t) => t.contentHash.equals(contentHash));
    } else {
      query.where((t) => t.contentHash.isNull());
    }

    return query.get();
  }

  Future<void> deleteAll() =>
      delete(fileRecordsTable).go();

  Future<Map<String, int>> getFileModifiedAgeStats(String accountId) async {
    final now = DateTime.now();
    final oneDayAgo = now.subtract(const Duration(days: 1)).millisecondsSinceEpoch;
    final sevenDaysAgo = now.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    final thirtyDaysAgo = now.subtract(const Duration(days: 30)).millisecondsSinceEpoch;
    final oneYearAgo = now.subtract(const Duration(days: 365)).millisecondsSinceEpoch;

    final rows = await customSelect(
      '''
      SELECT
        CASE
          WHEN modified_at >= ? THEN 'lt_1day'
          WHEN modified_at >= ? THEN '1_7days'
          WHEN modified_at >= ? THEN '7_30days'
          WHEN modified_at >= ? THEN '30d_1year'
          ELSE 'gt_1year'
        END as bucket,
        COUNT(*) as file_count
      FROM file_records
      WHERE account_id = ? AND is_folder = 0
      GROUP BY bucket
      ''',
      variables: [
        Variable.withInt(oneDayAgo),
        Variable.withInt(sevenDaysAgo),
        Variable.withInt(thirtyDaysAgo),
        Variable.withInt(oneYearAgo),
        Variable.withString(accountId),
      ],
      readsFrom: {fileRecordsTable},
    ).get();

    return {for (final r in rows) r.read<String>('bucket'): r.read<int>('file_count')};
  }

  Future<Map<int, int>> getDepthDistribution(String accountId) async {
    final rows = await customSelect(
      '''
      SELECT
        (LENGTH(path) - LENGTH(REPLACE(path, '/', ''))) as depth,
        COUNT(*) as count
      FROM file_records
      WHERE account_id = ?
      GROUP BY depth
      ORDER BY depth ASC
      LIMIT 20
      ''',
      variables: [Variable.withString(accountId)],
      readsFrom: {fileRecordsTable},
    ).get();

    return {for (final r in rows) r.read<int>('depth'): r.read<int>('count')};
  }

  Future<({int count, int wastedBytes})> getDuplicateSummary(String accountId) async {
    final rows = await customSelect(
      '''
      SELECT
        COALESCE(SUM(cnt - 1), 0) as dup_count,
        COALESCE(SUM((cnt - 1) * COALESCE(size_bytes, 0)), 0) as wasted_bytes
      FROM (
        SELECT size_bytes, COUNT(*) as cnt
        FROM file_records
        WHERE account_id = ? AND is_folder = 0 AND size_bytes > 0
        GROUP BY name, size_bytes, IFNULL(content_hash, '')
        HAVING COUNT(*) > 1
      )
      ''',
      variables: [Variable.withString(accountId)],
      readsFrom: {fileRecordsTable},
    ).get();

    if (rows.isEmpty) return (count: 0, wastedBytes: 0);
    return (
      count: rows.first.read<int?>('dup_count') ?? 0,
      wastedBytes: rows.first.read<int?>('wasted_bytes') ?? 0,
    );
  }

  Future<List<Map<String, dynamic>>> getFolderSizes(String accountId) async {
    // Recursive CTE: walks the full folder tree and aggregates ALL descendant
    // file sizes (not just direct children) into each folder's total.
    //
    // descendants columns:
    //   root_folder_id  — the top-level folder we started from (internal UUID)
    //   node_pfid       — provider_file_id of the current node (used as next
    //                     join key so children-of-children are found correctly)
    //   size_bytes      — null for folders, actual bytes for files
    //   is_folder       — controls whether we recurse further
    final rows = await customSelect(
      '''
      WITH RECURSIVE descendants(root_folder_id, node_pfid, size_bytes, is_folder) AS (

        -- Base: direct children of every folder in this account
        SELECT
          f.id              AS root_folder_id,
          c.provider_file_id,
          c.size_bytes,
          c.is_folder
        FROM file_records f
        JOIN file_records c
             ON  c.parent_id  = f.provider_file_id
             AND c.account_id = f.account_id
        WHERE f.account_id = ? AND f.is_folder = 1

        UNION ALL

        -- Recursive: children of sub-folders encountered so far
        SELECT
          d.root_folder_id,
          c.provider_file_id,
          c.size_bytes,
          c.is_folder
        FROM descendants d
        JOIN file_records c
             ON  c.parent_id  = d.node_pfid
             AND c.account_id = ?
        WHERE d.is_folder = 1
      )

      SELECT
        f.id,
        f.name,
        f.path,
        COALESCE(
          SUM(CASE WHEN d.is_folder = 0 THEN COALESCE(d.size_bytes, 0) ELSE 0 END),
          0
        ) AS total_bytes,
        COUNT(CASE WHEN d.is_folder = 0 THEN 1 ELSE NULL END) AS file_count
      FROM file_records f
      LEFT JOIN descendants d ON d.root_folder_id = f.id
      WHERE f.account_id = ? AND f.is_folder = 1
      GROUP BY f.id, f.name, f.path
      ORDER BY total_bytes DESC
      LIMIT ?
      ''',
      variables: [
        Variable.withString(accountId), // base case: folder filter
        Variable.withString(accountId), // recursive case: child filter
        Variable.withString(accountId), // outer query: folder filter
        Variable.withInt(AppConstants.maxFolderRankings),
      ],
      readsFrom: {fileRecordsTable},
    ).get();

    return rows
        .map((r) => {
              'id': r.read<String>('id'),
              'name': r.read<String>('name'),
              'path': r.read<String>('path'),
              'total_bytes': r.read<int?>('total_bytes') ?? 0,
              'file_count': r.read<int>('file_count'),
            })
        .toList();
  }

  Future<int> countFilesForAccount(String accountId) async {
    final result = await customSelect(
      'SELECT COUNT(*) as count FROM file_records WHERE account_id = ? AND is_folder = 0',
      variables: [Variable.withString(accountId)],
      readsFrom: {fileRecordsTable},
    ).getSingle();
    return result.read<int>('count');
  }

  /// Total bytes of files not modified in the last 365 days (stale/cold candidates).
  Future<int> getStaleDataSize(String accountId) async {
    final oneYearAgo = DateTime.now()
        .subtract(const Duration(days: 365))
        .millisecondsSinceEpoch;
    final result = await customSelect(
      'SELECT COALESCE(SUM(size_bytes), 0) as total '
      'FROM file_records '
      'WHERE account_id = ? AND is_folder = 0 AND modified_at < ?',
      variables: [
        Variable.withString(accountId),
        Variable.withInt(oneYearAgo),
      ],
      readsFrom: {fileRecordsTable},
    ).getSingle();
    return result.read<int?>('total') ?? 0;
  }

  /// Finds files that appear in MORE THAN ONE account (cross-account duplicates).
  /// Groups by name + size + content_hash. Returns the signature + list of account IDs.
  Future<List<Map<String, dynamic>>> findCrossAccountDuplicates() async {
    final rows = await customSelect(
      '''
      SELECT name, size_bytes, IFNULL(content_hash, '') as content_hash,
             COUNT(*) as total_copies,
             COUNT(DISTINCT account_id) as account_count,
             GROUP_CONCAT(DISTINCT account_id) as account_ids
      FROM file_records
      WHERE is_folder = 0 AND size_bytes > 0
      GROUP BY name, size_bytes, IFNULL(content_hash, '')
      HAVING COUNT(DISTINCT account_id) > 1
      ORDER BY size_bytes DESC
      ''',
      readsFrom: {fileRecordsTable},
    ).get();

    return rows
        .map((r) => {
              'name': r.read<String>('name'),
              'size_bytes': r.read<int?>('size_bytes') ?? 0,
              'content_hash': r.read<String?>('content_hash'),
              'total_copies': r.read<int>('total_copies'),
              'account_count': r.read<int>('account_count'),
              'account_ids': (r.read<String>('account_ids')).split(','),
            })
        .toList();
  }

  /// Gets all file records matching a cross-account duplicate signature.
  Future<List<FileRecordsTableData>> getFilesForCrossAccountSignature({
    required String name,
    required int sizeBytes,
    String? contentHash,
  }) {
    final query = select(fileRecordsTable)
      ..where((t) =>
          t.name.equals(name) &
          t.sizeBytes.equals(sizeBytes) &
          t.isFolder.equals(false));
    if (contentHash != null && contentHash.isNotEmpty) {
      query.where((t) => t.contentHash.equals(contentHash));
    } else {
      query.where((t) => t.contentHash.isNull());
    }
    return query.get();
  }

  /// Stale data breakdown by category for cost analysis.
  Future<List<Map<String, dynamic>>> getStaleDataByCategory(String accountId) async {
    final oneYearAgo = DateTime.now()
        .subtract(const Duration(days: 365))
        .millisecondsSinceEpoch;
    final rows = await customSelect(
      '''
      SELECT category, COUNT(*) as file_count, COALESCE(SUM(size_bytes), 0) as total_bytes
      FROM file_records
      WHERE account_id = ? AND is_folder = 0 AND modified_at < ?
      GROUP BY category
      ORDER BY total_bytes DESC
      ''',
      variables: [
        Variable.withString(accountId),
        Variable.withInt(oneYearAgo),
      ],
      readsFrom: {fileRecordsTable},
    ).get();

    return rows
        .map((r) => {
              'category': r.read<String>('category'),
              'file_count': r.read<int>('file_count'),
              'total_bytes': r.read<int?>('total_bytes') ?? 0,
            })
        .toList();
  }
}
