import '../../../data/repositories/file_repository.dart';
import '../../../domain/models/folder_rank.dart';

class GetFolderRankingsUseCase {
  const GetFolderRankingsUseCase(this._fileRepo);

  final FileRepository _fileRepo;

  Future<List<FolderRank>> execute(String accountId) =>
      _fileRepo.getFolderRankings(accountId);
}
