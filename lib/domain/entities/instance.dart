class Instance {
  final String id;
  final String name;
  final String instanceId;
  final String instanceToken;
  final bool isOnline;
  final double cpuUsage;
  final double memoryUsage;
  final int uptimeSeconds;
  final DateTime? lastSeen;
  final List<ProcessInfo> processes;
  final DateTime createdAt;

  Instance({
    required this.id,
    required this.name,
    required this.instanceId,
    required this.instanceToken,
    this.isOnline = false,
    this.cpuUsage = 0.0,
    this.memoryUsage = 0.0,
    this.uptimeSeconds = 0,
    this.lastSeen,
    this.processes = const [],
    required this.createdAt,
  });

  Instance copyWith({
    String? id,
    String? name,
    String? instanceId,
    String? instanceToken,
    bool? isOnline,
    double? cpuUsage,
    double? memoryUsage,
    int? uptimeSeconds,
    DateTime? lastSeen,
    List<ProcessInfo>? processes,
    DateTime? createdAt,
  }) {
    return Instance(
      id: id ?? this.id,
      name: name ?? this.name,
      instanceId: instanceId ?? this.instanceId,
      instanceToken: instanceToken ?? this.instanceToken,
      isOnline: isOnline ?? this.isOnline,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      memoryUsage: memoryUsage ?? this.memoryUsage,
      uptimeSeconds: uptimeSeconds ?? this.uptimeSeconds,
      lastSeen: lastSeen ?? this.lastSeen,
      processes: processes ?? this.processes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get uptimeFormatted {
    final days = uptimeSeconds ~/ 86400;
    final hours = (uptimeSeconds % 86400) ~/ 3600;
    final minutes = (uptimeSeconds % 3600) ~/ 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}

class ProcessInfo {
  final String channel;
  final String agent;
  final String status;
  final DateTime? startedAt;

  ProcessInfo({
    required this.channel,
    required this.agent,
    required this.status,
    this.startedAt,
  });
}
