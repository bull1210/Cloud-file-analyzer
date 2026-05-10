import '../../../data/repositories/auth_repository.dart';

class LogoutAccountUseCase {
  const LogoutAccountUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> execute(String accountId) => _repository.logout(accountId);
}
