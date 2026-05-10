import '../../../data/repositories/file_repository.dart';
import '../../../domain/models/file_type_breakdown.dart';

class GetFileTypeBreakdownUseCase {
  const GetFileTypeBreakdownUseCase(this._fileRepo);

  final FileRepository _fileRepo;

  Future<FileTypeBreakdownList> execute(String accountId) =>
      _fileRepo.getFileTypeBreakdown(accountId);
}
