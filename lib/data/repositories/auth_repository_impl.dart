import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/pocketbase_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final PocketBaseDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Future<User> login(String email, String password) {
    return _dataSource.login(email, password);
  }

  @override
  Future<User?> getCurrentUser() {
    return _dataSource.getCurrentUser();
  }

  @override
  Future<void> logout() {
    return _dataSource.logout();
  }

  @override
  Future<bool> isLoggedIn() {
    return _dataSource.isLoggedIn();
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _dataSource.register(
      name: name,
      email: email,
      password: password,
    );
  }

  @override
  Future<void> requestPasswordReset(String email) {
    return _dataSource.requestPasswordReset(email);
  }

  @override
  Future<void> resendVerificationEmail(String email) {
    return _dataSource.resendVerificationEmail(email);
  }

  @override
  Future<User?> refreshUserVerification() {
    return _dataSource.refreshUserVerification();
  }

  @override
  Future<String?> getRelayToken() {
    return _dataSource.getRelayToken();
  }

  @override
  Future<String?> regenerateRelayToken(String userId, String email) {
    return _dataSource.regenerateRelayToken(userId, email);
  }
}
