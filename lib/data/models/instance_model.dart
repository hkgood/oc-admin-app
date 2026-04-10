import '../../domain/entities/instance.dart';

class InstanceModel extends Instance {
  InstanceModel({
    required super.id,
    required super.name,
    required super.instanceId,
    required super.instanceToken,
    super.isOnline,
    super.cpuUsage,
    super.memoryUsage,
    super.uptimeSeconds,
    super.lastSeen,
    super.processes,
    required super.createdAt,
    super.version,
    super.currentModel,
    super.currentAgent,
    super.sessionCount,
    super.channelCount,
    super.nodeCount,
    super.onlineChannels,
    super.totalTokenUsage,
    super.thinking,
    super.lastMessageAgo,
  });

  factory InstanceModel.fromJson(Map<String, dynamic> json) {
    return InstanceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      instanceId: json['instance_id'] ?? '',
      instanceToken: json['instance_token'] ?? '',
      isOnline: json['is_online'] ?? false,
      cpuUsage: (json['cpu_usage'] ?? 0).toDouble(),
      memoryUsage: (json['memory_usage'] ?? 0).toDouble(),
      uptimeSeconds: json['uptime_seconds'] ?? 0,
      lastSeen: json['last_seen'] != null
          ? DateTime.tryParse(json['last_seen'])
          : null,
      processes: (json['processes'] as List<dynamic>?)
              ?.map((p) => ProcessInfoModel.fromJson(p))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      version: json['version'] ?? '',
      currentModel: json['currentModel'] ?? '',
      currentAgent: json['currentAgent'] ?? '',
      sessionCount: json['sessionCount'] ?? 0,
      channelCount: json['channelCount'] ?? 0,
      nodeCount: json['nodeCount'] ?? 0,
      onlineChannels: (json['onlineChannels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      totalTokenUsage: json['totalTokenUsage'] ?? 0,
      thinking: json['thinking'] ?? false,
      lastMessageAgo: json['lastMessageAgo'] ?? 0,
    );
  }

  /// Create InstanceModel from pebble-relay /api/v1/oc/instances response
  factory InstanceModel.fromDiscoveredJson(Map<String, dynamic> json) {
    return InstanceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      instanceId: json['id'] ?? '',
      instanceToken: '',
      isOnline: json['ok'] ?? false,
      cpuUsage: (json['cpu'] ?? 0).toDouble(),
      memoryUsage: (json['memory'] ?? 0).toDouble(),
      uptimeSeconds: json['uptime'] ?? 0,
      lastSeen: json['lastUpdate'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['lastUpdate'] as int) * 1000)
          : null,
      processes: [],
      createdAt: DateTime.now(),
      version: json['version'] ?? '',
      currentModel: json['currentModel'] ?? '',
      currentAgent: json['currentAgent'] ?? '',
      sessionCount: json['sessionCount'] ?? 0,
      channelCount: json['channelCount'] ?? 0,
      nodeCount: json['nodeCount'] ?? 0,
      onlineChannels: (json['onlineChannels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      totalTokenUsage: json['totalTokenUsage'] ?? 0,
      thinking: json['thinking'] ?? false,
      lastMessageAgo: json['lastMessageAgo'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'instance_id': instanceId,
      'instance_token': instanceToken,
      'is_online': isOnline,
      'cpu_usage': cpuUsage,
      'memory_usage': memoryUsage,
      'uptime_seconds': uptimeSeconds,
      'last_seen': lastSeen?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'version': version,
      'currentModel': currentModel,
      'currentAgent': currentAgent,
      'sessionCount': sessionCount,
      'channelCount': channelCount,
      'nodeCount': nodeCount,
      'onlineChannels': onlineChannels,
      'totalTokenUsage': totalTokenUsage,
      'thinking': thinking,
      'lastMessageAgo': lastMessageAgo,
    };
  }

  Instance toEntity() => this;
}

class ProcessInfoModel extends ProcessInfo {
  ProcessInfoModel({
    required super.channel,
    required super.agent,
    required super.status,
    super.startedAt,
  });

  factory ProcessInfoModel.fromJson(Map<String, dynamic> json) {
    return ProcessInfoModel(
      channel: json['channel'] ?? '',
      agent: json['agent'] ?? '',
      status: json['status'] ?? 'unknown',
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channel': channel,
      'agent': agent,
      'status': status,
      'started_at': startedAt?.toIso8601String(),
    };
  }
}
