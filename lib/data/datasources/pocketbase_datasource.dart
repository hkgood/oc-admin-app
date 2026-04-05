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
    await _secureStorage.write(key: _userKey, value: authData.record!.toJson());
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
      _pb.authStore.save(token, RecordModel.fromJson(jsonDecode(userJson)));
      // Also store userId for instance operations
      final userId = (_pb.authStore.model as RecordModel?)?.id;
      if (userId != null) {
        await _secureStorage.write(key: _userIdKey, value: userId);
      }
      if (!_pb.authStore.isValid) return false;
      // Verify token is still valid by refreshing
      await _pb.collection('relay_users').authRefresh();
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
    await _secureStorage.write(key: _userKey, value: authData.record!.toJson());
    return UserModel.fromJson(record.toJson());
  }

  // Request password reset email
  Future<void> requestPasswordReset(String email) async {
    await _pb.collection('relay_users').requestPasswordReset(email);
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
