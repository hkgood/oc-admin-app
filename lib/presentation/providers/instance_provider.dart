import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/instance.dart';
import '../../domain/repositories/instance_repository.dart';

enum InstanceStatus { initial, loading, loaded, error }

class InstanceProvider extends ChangeNotifier {
  final InstanceRepository _repository;

  InstanceStatus _status = InstanceStatus.initial;
  List<Instance> _instances = [];
  String? _errorMessage;
  Timer? _refreshTimer;

  InstanceProvider(this._repository);

  InstanceStatus get status => _status;
  List<Instance> get instances => _instances;
  String? get errorMessage => _errorMessage;

  List<Instance> get onlineInstances => _instances.where((i) => i.isOnline).toList();
  List<Instance> get offlineInstances => _instances.where((i) => !i.isOnline).toList();

  Future<void> loadInstances() async {
    _status = InstanceStatus.loading;
    notifyListeners();

    try {
      _instances = await _repository.getInstances();
      await _refreshAllStatuses();
      _status = InstanceStatus.loaded;
    } catch (e) {
      _status = InstanceStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> addInstance(String name, String instanceId, String instanceToken) async {
    try {
      final newInstance = await _repository.addInstance(name, instanceId, instanceToken);
      _instances = [newInstance, ..._instances];
      // Try to get live status
      final status = await _repository.getInstanceStatus(instanceId);
      if (status != null) {
        final idx = _instances.indexWhere((i) => i.id == newInstance.id);
        if (idx != -1) {
          _instances[idx] = newInstance.copyWith(
            isOnline: status.isOnline,
            cpuUsage: status.cpuUsage,
            memoryUsage: status.memoryUsage,
            uptimeSeconds: status.uptimeSeconds,
            lastSeen: status.lastSeen,
          );
        }
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeInstance(String instanceDbId) async {
    try {
      await _repository.removeInstance(instanceDbId);
      _instances.removeWhere((i) => i.id == instanceDbId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _refreshAllStatuses() async {
    final futures = _instances.map((instance) async {
      final status = await _repository.getInstanceStatus(instance.instanceId);
      return (instance.id, status);
    });

    final results = await Future.wait(futures);
    for (final (id, status) in results) {
      if (status != null) {
        final idx = _instances.indexWhere((i) => i.id == id);
        if (idx != -1) {
          _instances[idx] = _instances[idx].copyWith(
            isOnline: status.isOnline,
            cpuUsage: status.cpuUsage,
            memoryUsage: status.memoryUsage,
            uptimeSeconds: status.uptimeSeconds,
            lastSeen: status.lastSeen,
            processes: status.processes,
          );
        }
      }
    }
  }

  Future<Instance?> getInstanceProcesses(String instanceId) async {
    final instance = _instances.firstWhere(
      (i) => i.instanceId == instanceId,
      orElse: () => throw Exception('Instance not found'),
    );
    final processes = await _repository.getInstanceProcesses(instanceId);
    return instance.copyWith(processes: processes);
  }

  void startAutoRefresh({Duration interval = const Duration(seconds: 30)}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) async {
      if (_instances.isNotEmpty) {
        await _refreshAllStatuses();
        notifyListeners();
      }
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
