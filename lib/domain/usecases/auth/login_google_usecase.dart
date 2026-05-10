import '../../../data/repositories/auth_repository.dart';
import '../../models/cloud_account.dart';

class LoginGoogleUseCase {
  const LoginGoogleUseCase(this._repository);

  final AuthRepository _repository;

  Future<CloudAccount> execute() => _repository.loginGoogle();
}
