import '../entities/instance.dart';

abstract class InstanceRepository {
  Future<List<Instance>> getInstances();
  Future<Instance> addInstance(String name, String instanceId, String instanceToken);
  Future<void> removeInstance(String instanceDbId);
  Future<Instance?> getInstanceStatus(String instanceId);
  Future<List<ProcessInfo>> getInstanceProcesses(String instanceId);
  Future<void> refreshAllInstances();
}
