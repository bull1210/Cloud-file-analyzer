import '../data/local/database/app_database.dart';
import '../data/remote/google/google_drive_api.dart';
import '../data/remote/microsoft/onedrive_api.dart';
import '../domain/models/cloud_account.dart';
import '../domain/models/cloud_file.dart';

class DeleteResult {
  const DeleteResult({required this.deleted, required this.failed});

  final int deleted;

  /// Each entry is (file, human-readable error message).
  final List<(CloudFile, String)> failed;

  bool get hasErrors => failed.isNotEmpty;
}

/// Deletes files from their cloud provider and removes them from the local DB.
/// Both Google Drive and OneDrive move to Trash/Recycle Bin — not permanent delete.
class CloudDeleteService {
  const CloudDeleteService({
    required this.googleDriveApi,
    required this.oneDriveApi,
    required this.db,
  });

  final GoogleDriveApi googleDriveApi;
  final OneDriveApi oneDriveApi;
  final AppDatabase db;

  Future<DeleteResult> deleteFiles(List<CloudFile> files) async {
    int deleted = 0;
    final failed = <(CloudFile, String)>[];

    for (final file in files) {
      try {
        if (file.provider == CloudProvider.google) {
          await googleDriveApi.trashFile(file.accountId, file.providerFileId);
        } else {
          await oneDriveApi.deleteItem(file.accountId, file.providerFileId);
        }
        await db.fileRecordDao.deleteByLocalId(file.id);
        deleted++;
      } catch (e) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        failed.add((file, msg));
      }
    }
    return DeleteResult(deleted: deleted, failed: failed);
  }
}
