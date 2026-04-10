import '../../domain/entities/instance.dart';
import '../../domain/repositories/instance_repository.dart';
import '../datasources/pocketbase_datasource.dart';
import '../datasources/relay_api_datasource.dart';
import '../models/instance_model.dart';

class InstanceRepositoryImpl implements InstanceRepository {
  final PocketBaseDataSource _pbDataSource;
  final RelayApiDataSource _relayDataSource;

  InstanceRepositoryImpl(this._pbDataSource, this._relayDataSource);

  @override
  Future<List<Instance>> getInstances() async {
    final pocketbaseInstances = await _pbDataSource.getInstances();

    // Auto-discover watch-claw registered instances via pebble-relay
    try {
      final relayToken = await _pbDataSource.getRelayToken();
      if (relayToken != null && relayToken.isNotEmpty) {
        final discovered = await _relayDataSource.discoverInstances(relayToken);
        if (discovered.isNotEmpty) {
          final existingIds = {for (var i in pocketbaseInstances) i.id};
          for (final d in discovered) {
            final id = d['id'] as String;
            if (!existingIds.contains(id)) {
              pocketbaseInstances.add(InstanceModel.fromDiscoveredJson(d));
            }
          }
        }
      }
    } catch (_) {
      // Ignore discovery errors - fall back to PocketBase instances only
    }

    return pocketbaseInstances;
  }

  @override
  Future<Instance> addInstance(String name, String instanceId, String instanceToken) {
    return _pbDataSource.addInstance(name, instanceId, instanceToken);
  }

  @override
  Future<void> removeInstance(String instanceDbId) {
    return _pbDataSource.removeInstance(instanceDbId);
  }

  @override
  Future<Instance?> getInstanceStatus(String instanceId) async {
    final status = await _relayDataSource.getInstanceStatus(instanceId);
    if (status == null) return null;

    return InstanceModel(
      id: '',
      name: status['name'] ?? instanceId,
      instanceId: instanceId,
      instanceToken: '',
      isOnline: status['ok'] ?? false,
      cpuUsage: (status['cpu'] ?? 0).toDouble(),
      memoryUsage: (status['memory'] ?? 0).toDouble(),
      uptimeSeconds: status['uptime'] ?? 0,
      lastSeen: DateTime.now(),
      processes: (status['processes'] as List<dynamic>?)
              ?.map((p) => ProcessInfoModel.fromJson(p))
              .toList() ??
          [],
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<ProcessInfo>> getInstanceProcesses(String instanceId) {
    return _relayDataSource.getInstanceProcesses(instanceId);
  }

  @override
  Future<void> refreshAllInstances() async {
    // This is handled by the provider with polling
  }
}
