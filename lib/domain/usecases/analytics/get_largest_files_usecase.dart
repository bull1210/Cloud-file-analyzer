import '../../../data/repositories/file_repository.dart';
import '../../../domain/models/cloud_file.dart';

class GetLargestFilesUseCase {
  const GetLargestFilesUseCase(this._fileRepo);

  final FileRepository _fileRepo;

  Future<List<CloudFile>> execute(String accountId, {int limit = 15}) =>
      _fileRepo.getLargestFiles(accountId, limit: limit);
}
