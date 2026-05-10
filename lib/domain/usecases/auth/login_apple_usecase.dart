import '../../../data/repositories/auth_repository.dart';
import '../../models/cloud_account.dart';

class LoginAppleUseCase {
  const LoginAppleUseCase(this._repository);

  final AuthRepository _repository;

  Future<CloudAccount> execute() => _repository.loginApple();
}
