import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/instance.dart';
import '../models/instance_model.dart';

class RelayApiDataSource {
  // pebble-relay API base - query instance status from relay
  // The relay aggregates watch-claw plugin data
  static const _relayBase = 'http://115.29.162.18:8977';

  // Register instance with relay (called by the OpenClaw instance itself)
  // App uses this to check if an instance is registered
  Future<Map<String, dynamic>?> getInstanceStatus(String instanceId) async {
    try {
      final resp = await http.get(
        Uri.parse('$_relayBase/api/v1/oc/status/$instanceId'),
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> registerInstance({
    required String instanceId,
    required String instanceToken,
    required String instanceName,
    String? relayUrl,
  }) async {
    try {
      final resp = await http.post(
        Uri.parse('$_relayBase/api/v1/oc/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'instance_id': instanceId,
          'instance_token': instanceToken,
          'name': instanceName,
          'relay_url': relayUrl,
        }),
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return jsonDecode(resp.body);
      }
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllInstanceStatuses(List<String> instanceIds) async {
    final results = <Map<String, dynamic>>[];
    for (final id in instanceIds) {
      final status = await getInstanceStatus(id);
      if (status != null) {
        results.add(status);
      }
    }
    return results;
  }

  // Auto-discover all OpenClaw instances for the user (via relay_token)
  Future<List<Map<String, dynamic>>> discoverInstances(String relayToken) async {
    try {
      final resp = await http.get(
        Uri.parse('$_relayBase/api/v1/oc/instances'),
        headers: {
          'Content-Type': 'application/json',
          'X-User-Token': relayToken,
        },
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return List<Map<String, dynamic>>.from(data['instances'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  // Get process list from relay for an instance
  Future<List<ProcessInfo>> getInstanceProcesses(String instanceId) async {
    try {
      final resp = await http.get(
        Uri.parse('$_relayBase/api/v1/oc/processes/$instanceId'),
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List<dynamic>;
        return data.map((p) => ProcessInfoModel.fromJson(p)).toList();
      }
    } catch (_) {}
    return [];
  }
}
