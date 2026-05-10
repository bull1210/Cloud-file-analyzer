import '../../models/cloud_account.dart';
import '../../../data/repositories/auth_repository.dart';

class LoginMegaUseCase {
  const LoginMegaUseCase(this._repository);
  final AuthRepository _repository;

  Future<CloudAccount> execute({
    required String email,
    required String password,
  }) =>
      _repository.loginMega(email: email, password: password);
}
