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

  // Extended fields from relay API / pebble-relay
  final String version;
  final String currentModel;
  final String currentAgent;
  final int sessionCount;
  final int channelCount;
  final int nodeCount;
  final List<String> onlineChannels;
  final int totalTokenUsage;
  final bool thinking;
  final int lastMessageAgo; // seconds since last message

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
    this.version = '',
    this.currentModel = '',
    this.currentAgent = '',
    this.sessionCount = 0,
    this.channelCount = 0,
    this.nodeCount = 0,
    this.onlineChannels = const [],
    this.totalTokenUsage = 0,
    this.thinking = false,
    this.lastMessageAgo = 0,
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
    String? version,
    String? currentModel,
    String? currentAgent,
    int? sessionCount,
    int? channelCount,
    int? nodeCount,
    List<String>? onlineChannels,
    int? totalTokenUsage,
    bool? thinking,
    int? lastMessageAgo,
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
      version: version ?? this.version,
      currentModel: currentModel ?? this.currentModel,
      currentAgent: currentAgent ?? this.currentAgent,
      sessionCount: sessionCount ?? this.sessionCount,
      channelCount: channelCount ?? this.channelCount,
      nodeCount: nodeCount ?? this.nodeCount,
      onlineChannels: onlineChannels ?? this.onlineChannels,
      totalTokenUsage: totalTokenUsage ?? this.totalTokenUsage,
      thinking: thinking ?? this.thinking,
      lastMessageAgo: lastMessageAgo ?? this.lastMessageAgo,
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

  String get tokenUsageFormatted {
    if (totalTokenUsage < 1000) return totalTokenUsage.toString();
    if (totalTokenUsage < 1000000) return '${(totalTokenUsage / 1000).toStringAsFixed(1)}K';
    return '${(totalTokenUsage / 1000000).toStringAsFixed(1)}M';
  }

  String get lastMessageAgoFormatted {
    if (lastMessageAgo < 60) return '${lastMessageAgo}s';
    if (lastMessageAgo < 3600) return '${lastMessageAgo ~/ 60}m';
    return '${lastMessageAgo ~/ 3600}h';
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
