import '../../models/cloud_account.dart';
import '../../../data/repositories/auth_repository.dart';

class LoginTeraboxUseCase {
  const LoginTeraboxUseCase(this._repository);
  final AuthRepository _repository;
  Future<CloudAccount> execute() => _repository.loginTerabox();
}
