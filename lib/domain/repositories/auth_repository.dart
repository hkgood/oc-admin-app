import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<User?> getCurrentUser();
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<User> register({
    required String name,
    required String email,
    required String password,
  });
  Future<void> requestPasswordReset(String email);
}
