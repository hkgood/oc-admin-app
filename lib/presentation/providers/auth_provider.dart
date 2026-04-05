import 'package:flutter/foundation.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  AuthProvider(this._repository);

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> checkAuth() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final loggedIn = await _repository.isLoggedIn();
      if (loggedIn) {
        _user = await _repository.getCurrentUser();
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _repository.login(email, password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _repository.register(
        name: name,
        email: email,
        password: password,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _parseRegisterError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    _errorMessage = null;
    try {
      await _repository.requestPasswordReset(email);
      return true;
    } catch (e) {
      _errorMessage = _parseResetError(e);
      return false;
    }
  }

  String _parseError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid') || msg.contains('wrong') || msg.contains('credentials')) {
      return '邮箱或密码错误';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return '网络连接失败，请检查网络';
    }
    return '登录失败，请重试';
  }

  String _parseRegisterError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('already') || msg.contains('exists') || msg.contains('duplicate')) {
      return '该邮箱已注册';
    }
    if (msg.contains('email')) {
      return '邮箱格式不正确';
    }
    if (msg.contains('password')) {
      return '密码格式不正确';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return '网络连接失败，请检查网络';
    }
    return '注册失败，请重试';
  }

  String _parseResetError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('not found') || msg.contains('not exist') || msg.contains('invalid email')) {
      return '该邮箱未注册';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return '网络连接失败，请检查网络';
    }
    return '请求失败，请重试';
  }
}
