import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../models/instance_model.dart';

class PocketBaseDataSource {
  static const _pbUrl = 'https://pb.osglab.com/_/';
  static const _tokenKey = 'pb_auth_token';
  static const _userKey = 'pb_auth_model';

  late final PocketBase _pb;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  PocketBaseDataSource() {
    _pb = PocketBase(_pbUrl);
  }

  PocketBase get client => _pb;

  // Auth
  Future<UserModel> login(String email, String password) async {
    final authData = await _pb.collection('users').authWithPassword(email, password);
    await _secureStorage.write(key: _tokenKey, value: authData.token);
    await _secureStorage.write(key: _userKey, value: authData.record!.id);
    return UserModel.fromJson(authData.record!.toJson());
  }

  Future<void> logout() async {
    _pb.authStore.clear();
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token == null) return false;
    try {
      _pb.authStore.loadFromToken(token);
      return _pb.authStore.isValid;
    } catch (_) {
      return false;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    if (!_pb.authStore.isValid) return null;
    try {
      final record = await _pb.collection('users').authRefresh();
      return UserModel.fromJson(record!.toJson());
    } catch (_) {
      return null;
    }
  }

  // Instances
  Future<List<InstanceModel>> getInstances() async {
    final userId = await _secureStorage.read(key: _userKey);
    if (userId == null) return [];

    final records = await _pb.collection('openclaw_instances').getFullList(
      filter: 'user = "$userId"',
      sort: '-created',
    );
    return records.map((r) => InstanceModel.fromJson(r.toJson())).toList();
  }

  Future<InstanceModel> addInstance(String name, String instanceId, String instanceToken) async {
    final userId = await _secureStorage.read(key: _userKey);
    final record = await _pb.collection('openclaw_instances').create(
      body: {
        'name': name,
        'instance_id': instanceId,
        'instance_token': instanceToken,
        'user': userId,
        'is_online': false,
        'cpu_usage': 0.0,
        'memory_usage': 0.0,
        'uptime_seconds': 0,
      },
    );
    return InstanceModel.fromJson(record.toJson());
  }

  Future<void> removeInstance(String instanceDbId) async {
    await _pb.collection('openclaw_instances').delete(instanceDbId);
  }

  Future<void> updateInstanceStatus(String instanceDbId, Map<String, dynamic> data) async {
    await _pb.collection('openclaw_instances').update(instanceDbId, body: data);
  }
}
