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
  Future<void> resendVerificationEmail(String email);
  Future<User?> refreshUserVerification();
  Future<String?> getRelayToken();
  Future<String?> regenerateRelayToken(String userId, String email);
}
