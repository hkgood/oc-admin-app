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
    // First try pebble-relay auto-discovery (correctly uses relayUserId)
    try {
      final relayToken = await _pbDataSource.getRelayToken();
      if (relayToken != null && relayToken.isNotEmpty) {
        final discovered = await _relayDataSource.discoverInstances(relayToken);
        if (discovered.isNotEmpty) {
          return discovered
              .map((d) => InstanceModel.fromDiscoveredJson(d))
              .toList();
        }
      }
    } catch (_) {
      // Fall through to PocketBase query
    }

    // Fallback: try PocketBase manual instances
    return _pbDataSource.getInstances();
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
    // Try relay API first (has latest status for all discovered instances)
    try {
      final relayToken = await _pbDataSource.getRelayToken();
      if (relayToken != null && relayToken.isNotEmpty) {
        final discovered = await _relayDataSource.discoverInstances(relayToken);
        for (final d in discovered) {
          if (d['id'] == instanceId) {
            return InstanceModel.fromDiscoveredJson(d);
          }
        }
      }
    } catch (_) {
      // Fall through
    }

    // Fallback: PocketBase for manual instances
    try {
      final pbInstances = await _pbDataSource.getInstances();
      return pbInstances.where((i) => i.instanceId == instanceId).firstOrNull;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ProcessInfo>> getInstanceProcesses(String instanceId) {
    return _relayDataSource.getInstanceProcesses(instanceId);
  }

  @override
  Future<void> refreshAllInstances() async {
    // Handled by provider polling - no-op here
  }
}
