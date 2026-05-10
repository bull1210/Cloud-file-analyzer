import '../../domain/models/access_time_stats.dart';
import '../../domain/models/cloud_file.dart';
import '../../domain/models/duplicate_group.dart';
import '../../domain/models/file_type_breakdown.dart';
import '../../domain/models/folder_rank.dart';
import '../../core/utils/file_type_utils.dart';
import '../local/database/app_database.dart';
import 'file_repository.dart';
import '../../domain/models/cloud_account.dart';

class FileRepositoryImpl implements FileRepository {
  FileRepositoryImpl({required this.db});

  final AppDatabase db;

  @override
  Future<List<CloudFile>> getFiles({
    required String accountId,
    int limit = 50,
    int offset = 0,
    String? nameFilter,
    String? categoryFilter,
    bool filesOnly = true,
    int? minSizeBytes,
    int? maxSizeBytes,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    String sortColumn = 'size_bytes',
    bool sortAsc = false,
  }) async {
    final rows = await db.fileRecordDao.getFilesForAccount(
      accountId: accountId,
      limit: limit,
      offset: offset,
      nameFilter: nameFilter,
      categoryFilter: categoryFilter,
      filesOnly: filesOnly,
      minSizeBytes: minSizeBytes,
      maxSizeBytes: maxSizeBytes,
      modifiedAfter: modifiedAfter,
      modifiedBefore: modifiedBefore,
      sortColumn: sortColumn,
      sortAsc: sortAsc,
    );
    return rows.map(_mapFile).toList();
  }

  @override
  Future<List<CloudFile>> getLargestFiles(String accountId,
      {int limit = 15}) async {
    final rows =
        await db.fileRecordDao.getLargestFiles(accountId: accountId, limit: limit);
    return rows.map(_mapFile).toList();
  }

  @override
  Future<List<CloudFile>> getChildren(String accountId, String parentId) async {
    final rows = await db.fileRecordDao
        .getChildrenOf(accountId: accountId, parentId: parentId);
    return rows.map(_mapFile).toList();
  }

  @override
  Future<List<CloudFile>> getTopLevel(String accountId) async {
    final rows = await db.fileRecordDao.getTopLevelItems(accountId);
    return rows.map(_mapFile).toList();
  }

  @override
  Future<FileTypeBreakdownList> getFileTypeBreakdown(String accountId) async {
    final rows =
        await db.fileRecordDao.getCategoryBreakdownFull(accountId);
    final items = rows.map((r) {
      final cat = FileCategory.values.firstWhere(
        (c) => c.name == (r['category'] as String),
        orElse: () => FileCategory.other,
      );
      return FileTypeBreakdown(
        category: cat,
        fileCount: r['file_count'] as int,
        totalBytes: r['total_bytes'] as int,
      );
    }).toList();
    return FileTypeBreakdownList(items);
  }

  @override
  Future<List<FolderRank>> getFolderRankings(String accountId) async {
    final rows = await db.fileRecordDao.getFolderSizes(accountId);
    return rows
        .map((r) => FolderRank(
              folderId: r['id'] as String,
              folderName: r['name'] as String,
              folderPath: r['path'] as String,
              accountId: accountId,
              totalBytes: r['total_bytes'] as int,
              fileCount: r['file_count'] as int,
            ))
        .toList();
  }

  @override
  Future<AccessTimeStatsList> getAccessTimeStats(String accountId) async {
    final rows = await db.fileRecordDao.getAccessTimeStats(accountId);
    final stats = rows.map((r) {
      final bucket = AccessTimeBucket.values.firstWhere(
        (b) => b.name == (r['bucket'] as String),
        orElse: () => AccessTimeBucket.never,
      );
      return AccessTimeStats(
        bucket: bucket,
        fileCount: r['file_count'] as int,
        totalBytes: r['total_bytes'] as int,
      );
    }).toList();
    return AccessTimeStatsList(stats);
  }

  @override
  Future<List<CloudFile>> getFilesByAccessBucket({
    required String accountId,
    required AccessTimeBucket bucket,
    int limit = 100,
    int offset = 0,
  }) async {
    final rows = await db.fileRecordDao.getFilesByAccessBucket(
      accountId: accountId,
      bucket: bucket.name,
      limit: limit,
      offset: offset,
    );
    return rows.map(_mapFile).toList();
  }

  @override
  Future<List<DuplicateGroup>> findDuplicates(String accountId) async {
    final signatures =
        await db.fileRecordDao.findDuplicateSignatures(accountId);

    final groups = <DuplicateGroup>[];
    for (final sig in signatures) {
      final name = sig['name'] as String;
      final size = sig['size_bytes'] as int;
      final hash = sig['content_hash'] as String?;

      final rows = await db.fileRecordDao.getFilesWithSignature(
        accountId: accountId,
        name: name,
        sizeBytes: size,
        contentHash: hash,
      );

      if (rows.length > 1) {
        // Include hash algorithm in signature so the UI can show confidence level.
        final sig = hash != null ? '$name::$size::$hash' : '$name::$size';
        groups.add(DuplicateGroup(
          signature: sig,
          files: rows.map(_mapFile).toList(),
        ));
      }
    }

    groups.sort((a, b) => b.wastedBytes.compareTo(a.wastedBytes));
    return groups;
  }

  @override
  Future<Map<String, int>> getFileAgeStats(String accountId) =>
      db.fileRecordDao.getFileModifiedAgeStats(accountId);

  @override
  Future<Map<int, int>> getDepthDistribution(String accountId) =>
      db.fileRecordDao.getDepthDistribution(accountId);

  @override
  Future<({int count, int wastedBytes})> getDuplicateSummary(String accountId) =>
      db.fileRecordDao.getDuplicateSummary(accountId);

  @override
  Future<int> getStaleDataSize(String accountId) =>
      db.fileRecordDao.getStaleDataSize(accountId);

  @override
  Future<List<Map<String, dynamic>>> getStaleDataByCategory(String accountId) =>
      db.fileRecordDao.getStaleDataByCategory(accountId);

  @override
  Future<List<Map<String, dynamic>>> findCrossAccountDuplicates() =>
      db.fileRecordDao.findCrossAccountDuplicates();

  CloudFile _mapFile(FileRecordsTableData row) {
    return CloudFile(
      id: row.id,
      accountId: row.accountId,
      provider: CloudProviderExtension.fromDb(row.provider),
      name: row.name,
      path: row.path,
      sizeBytes: row.sizeBytes,
      mimeType: row.mimeType,
      category: FileCategory.values.firstWhere(
        (c) => c.name == row.category,
        orElse: () => FileCategory.other,
      ),
      isFolder: row.isFolder,
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(row.modifiedAt),
      accessedAt: row.accessedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.accessedAt!)
          : null,
      parentId: row.parentId,
      providerFileId: row.providerFileId,
      contentHash: row.contentHash,
    );
  }
}
