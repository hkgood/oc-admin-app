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
}
