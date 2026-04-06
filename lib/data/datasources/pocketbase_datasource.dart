import 'dart:convert';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../models/instance_model.dart';

class PocketBaseDataSource {
  static const _pbUrl = 'https://pb.osglab.com';
  static const _tokenKey = 'pb_auth_token';
  static const _userKey = 'pb_auth_model';
  static const _userIdKey = 'pb_auth_user_id';

  late final PocketBase _pb;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  PocketBaseDataSource() {
    _pb = PocketBase(_pbUrl);
  }

  PocketBase get client => _pb;

  // Auth - use relay_users collection
  Future<UserModel> login(String email, String password) async {
    final authData = await _pb.collection('relay_users').authWithPassword(email, password);
    await _secureStorage.write(key: _tokenKey, value: authData.token);
    await _secureStorage.write(key: _userKey, value: jsonEncode(authData.record!.toJson()));
    await _secureStorage.write(key: _userIdKey, value: authData.record!.id);
    return UserModel.fromJson(authData.record!.toJson());
  }

  Future<void> logout() async {
    _pb.authStore.clear();
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userKey);
    await _secureStorage.delete(key: _userIdKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: _tokenKey);
    final userJson = await _secureStorage.read(key: _userKey);
    if (token == null || userJson == null) return false;
    try {
      // Restore auth store from stored token + model
      final model = RecordModel.fromJson(jsonDecode(userJson));
      _pb.authStore.save(token, model);
      // Also store userId for instance operations
      if (model.id.isNotEmpty) {
        await _secureStorage.write(key: _userIdKey, value: model.id);
      }
      if (!_pb.authStore.isValid) return false;
      // Verify token is still valid by refreshing (but don't fail if unverified)
      try {
        await _pb.collection('relay_users').authRefresh();
      } catch (_) {
        // Token valid even if refresh fails (e.g. unverified email)
        // As long as authStore is valid, user is logged in
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    if (!_pb.authStore.isValid) return null;
    try {
      final record = await _pb.collection('relay_users').authRefresh();
      return record != null ? UserModel.fromJson(record.toJson()) : null;
    } catch (_) {
      return null;
    }
  }

  // Register new user
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final record = await _pb.collection('relay_users').create(
      body: {
        'name': name,
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'emailVisibility': false,
      },
    );
    // Auto-login after registration
    final authData = await _pb.collection('relay_users').authWithPassword(email, password);
    await _secureStorage.write(key: _tokenKey, value: authData.token);
    await _secureStorage.write(key: _userKey, value: jsonEncode(authData.record!.toJson()));

    // 发送验证邮件
    await _pb.collection('relay_users').requestVerification(email);

    return UserModel.fromJson(authData.record!.toJson());
  }

  // Request password reset email
  Future<void> requestPasswordReset(String email) async {
    await _pb.collection('relay_users').requestPasswordReset(email);
  }

  // Resend verification email
  Future<void> resendVerificationEmail(String email) async {
    await _pb.collection('relay_users').requestVerification(email);
  }

  // Refresh current user's verification status from server
  Future<UserModel?> refreshUserVerification() async {
    if (!_pb.authStore.isValid) return null;
    try {
      final record = await _pb.collection('relay_users').authRefresh();
      if (record != null) {
        final user = UserModel.fromJson(record.toJson());
        await _secureStorage.write(key: _userKey, value: jsonEncode(record.toJson()));
        return user;
      }
    } catch (_) {}
    return null;
  }

  // Instances - use relay_users as the owner
  Future<List<InstanceModel>> getInstances() async {
    final userId = await _secureStorage.read(key: _userIdKey);
    if (userId == null) return [];

    final records = await _pb.collection('oc_instances').getFullList(
      filter: 'user_id = "' + userId + '"',
      sort: '-created',
    );
    return records.map((r) => InstanceModel.fromJson(r.toJson())).toList();
  }

  // Get instance status from relay_status collection
  Future<Map<String, dynamic>?> getInstanceStatusFromPB(String instanceId) async {
    try {
      final records = await _pb.collection('relay_status').getFullList(
        filter: 'instance_id = "' + instanceId + '"',
        sort: '-lastUpdate',
      );
      if (records.isNotEmpty) {
        return records.first.toJson();
      }
    } catch (_) {}
    return null;
  }

  Future<InstanceModel> addInstance(String name, String instanceId, String instanceToken) async {
    final userId = await _secureStorage.read(key: _userIdKey);
    if (userId == null) throw Exception('Not logged in');

    final record = await _pb.collection('oc_instances').create(
      body: {
        'name': name,
        'instance_id': instanceId,
        'instance_token': instanceToken,
        'user_id': userId,
      },
    );
    return InstanceModel.fromJson(record.toJson());
  }

  Future<void> removeInstance(String instanceDbId) async {
    await _pb.collection('oc_instances').delete(instanceDbId);
  }

  Future<void> updateInstanceStatus(String instanceDbId, Map<String, dynamic> data) async {
    await _pb.collection('oc_instances').update(instanceDbId, body: data);
  }
}
