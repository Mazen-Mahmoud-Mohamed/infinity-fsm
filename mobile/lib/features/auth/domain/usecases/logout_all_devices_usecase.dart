import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';

class LogoutAllDevicesUseCase {
  const LogoutAllDevicesUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() {
    return _repository.logoutAllDevices();
  }
}
