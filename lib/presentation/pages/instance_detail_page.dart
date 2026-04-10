import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/instance.dart';
import '../providers/instance_provider.dart';

class InstanceDetailPage extends StatefulWidget {
  final String instanceId;

  const InstanceDetailPage({super.key, required this.instanceId});

  @override
  State<InstanceDetailPage> createState() => _InstanceDetailPageState();
}

class _InstanceDetailPageState extends State<InstanceDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ProcessInfo> _processes = [];
  bool _loadingProcesses = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProcesses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProcesses() async {
    setState(() => _loadingProcesses = true);
    try {
      final provider = context.read<InstanceProvider>();
      final instance = await provider.getInstanceProcesses(widget.instanceId);
      if (mounted && instance != null) {
        setState(() => _processes = instance.processes);
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loadingProcesses = false);
    }
  }

  Instance _findInstance(InstanceProvider provider) {
    try {
      return provider.instances.firstWhere(
        (i) => i.instanceId == widget.instanceId,
      );
    } catch (_) {
      return Instance(
        id: widget.instanceId,
        name: '加载中…',
        instanceId: widget.instanceId,
        instanceToken: '',
        createdAt: DateTime.now(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InstanceProvider>(
      builder: (context, provider, _) {
        final instance = _findInstance(provider);

        return Scaffold(
          appBar: AppBar(
            title: Text(instance.name),
            backgroundColor: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '系统'),
                Tab(text: '运行'),
                Tab(text: '进程'),
                Tab(text: '信息'),
              ],
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                _InstanceStatusBar(instance: instance),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _SystemTab(instance: instance),
                      _RuntimeTab(instance: instance),
                      _ProcessTab(
                        processes: _processes,
                        loading: _loadingProcesses,
                        onRefresh: _loadProcesses,
                      ),
                      _InfoTab(instance: instance),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Status Bar ───────────────────────────────────────────────────────────────

class _InstanceStatusBar extends StatelessWidget {
  final Instance instance;

  const _InstanceStatusBar({required this.instance});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.tertiary],
        ),
      ),
      child: Row(
        children: [
          _StatusDot(isOnline: instance.isOnline, thinking: instance.thinking),
          const SizedBox(width: 8),
          Text(
            _statusLabel(instance),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          _MetricChip(icon: Icons.memory, label: 'CPU', value: '${instance.cpuUsage.toStringAsFixed(0)}%'),
          const SizedBox(width: 12),
          _MetricChip(icon: Icons.storage, label: '内存', value: '${instance.memoryUsage.toStringAsFixed(0)}%'),
          const SizedBox(width: 12),
          _MetricChip(icon: Icons.timer, label: '运行时长', value: instance.uptimeFormatted),
        ],
      ),
    );
  }

  String _statusLabel(Instance i) {
    if (!i.isOnline) return '离线';
    if (i.thinking) return '思考中…';
    return '在线';
  }
}

class _StatusDot extends StatelessWidget {
  final bool isOnline;
  final bool thinking;

  const _StatusDot({required this.isOnline, required this.thinking});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    if (isOnline) color = thinking ? Colors.orangeAccent : Colors.greenAccent;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: isOnline ? [BoxShadow(color: color, blurRadius: 6)] : null,
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10),
        ),
      ],
    );
  }
}

// ─── System Tab ───────────────────────────────────────────────────────────────

class _SystemTab extends StatelessWidget {
  final Instance instance;

  const _SystemTab({required this.instance});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // CPU + Memory gauges
        Row(
          children: [
            Expanded(child: _GaugeCard(label: 'CPU', value: instance.cpuUsage, color: _cpuColor(instance.cpuUsage))),
            const SizedBox(width: 12),
            Expanded(child: _GaugeCard(label: '内存', value: instance.memoryUsage, color: _memoryColor(instance.memoryUsage))),
          ],
        ),
        const SizedBox(height: 16),

        // System info
        _Card(
          title: '系统信息',
          icon: Icons.widgets,
          children: [
            _Row('运行时长', instance.uptimeFormatted),
            _Divider(),
            _Row('最后活跃', instance.lastSeen != null
                ? DateFormat('yyyy-MM-dd HH:mm').format(instance.lastSeen!)
                : '未知'),
            _Divider(),
            _Row('最后消息', instance.lastMessageAgo > 0 ? instance.lastMessageAgoFormatted : '无'),
            _Divider(),
            _Row('OpenClaw 版本', instance.version.isNotEmpty ? instance.version : '未知'),
            _Divider(),
            _Row('CPU 使用率', '${instance.cpuUsage.toStringAsFixed(1)}%'),
            _Divider(),
            _Row('内存使用率', '${instance.memoryUsage.toStringAsFixed(1)}%'),
          ],
        ),
      ],
    );
  }

  Color _cpuColor(double v) {
    if (v < 50) return Colors.green;
    if (v < 80) return Colors.orange;
    return Colors.red;
  }

  Color _memoryColor(double v) {
    if (v < 60) return Colors.blue;
    if (v < 85) return Colors.orange;
    return Colors.red;
  }
}

class _GaugeCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _GaugeCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            SizedBox(
              width: 90,
              height: 90,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: value / 100,
                      strokeWidth: 8,
                      backgroundColor: color.withAlpha(30),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                  Text(
                    '${value.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Runtime Tab ─────────────────────────────────────────────────────────────

class _RuntimeTab extends StatelessWidget {
  final Instance instance;

  const _RuntimeTab({required this.instance});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Current state
        _Card(
          title: '当前状态',
          icon: Icons.smart_toy,
          children: [
            _Row('当前模型', instance.currentModel.isNotEmpty ? instance.currentModel : '未设置'),
            _Divider(),
            _Row('当前 Agent', instance.currentAgent.isNotEmpty ? instance.currentAgent : '未设置'),
            _Divider(),
            _Row('活跃频道', instance.onlineChannels.isNotEmpty ? instance.onlineChannels.join(', ') : '无'),
          ],
        ),
        const SizedBox(height: 16),

        // Statistics
        _Card(
          title: '统计数据',
          icon: Icons.bar_chart,
          children: [
            Row(
              children: [
                Expanded(child: _StatBox(label: '会话', value: '${instance.sessionCount}', color: Colors.blue)),
                const SizedBox(width: 8),
                Expanded(child: _StatBox(label: '频道', value: '${instance.channelCount}', color: Colors.purple)),
                const SizedBox(width: 8),
                Expanded(child: _StatBox(label: '节点', value: '${instance.nodeCount}', color: Colors.teal)),
              ],
            ),
            const SizedBox(height: 12),
            _StatBox(label: '累计 Token', value: instance.tokenUsageFormatted, color: Colors.amber, wide: true),
          ],
        ),
        const SizedBox(height: 16),

        // Thinking indicator
        if (instance.thinking)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.orange),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'AI 正在思考（${instance.currentModel}）',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        if (!instance.thinking)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 12),
                Text(
                  '正常运行中',
                  style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool wide;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    if (wide) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.token, color: color, size: 24),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: color)),
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

// ─── Process Tab ──────────────────────────────────────────────────────────────

class _ProcessTab extends StatelessWidget {
  final List<ProcessInfo> processes;
  final bool loading;
  final VoidCallback onRefresh;

  const _ProcessTab({
    required this.processes,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (processes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              '暂无进程信息',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 8),
            Text(
              '进程信息由 watch-claw 插件定期上报',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: processes.length,
        itemBuilder: (context, index) {
          final p = processes[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _statusColor(p.status).withAlpha(30),
                child: Icon(Icons.smart_toy, color: _statusColor(p.status), size: 20),
              ),
              title: Text(p.agent.isEmpty ? p.channel : p.agent),
              subtitle: Text('Channel: ${p.channel}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(p.status).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(p.status, style: TextStyle(color: _statusColor(p.status), fontSize: 12)),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'running': return Colors.green;
      case 'idle':   return Colors.blue;
      case 'error':  return Colors.red;
      default:       return Colors.grey;
    }
  }
}

// ─── Info Tab ─────────────────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  final Instance instance;

  const _InfoTab({required this.instance});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Card(
          title: '基本信息',
          icon: Icons.info_outline,
          children: [
            _Row('名称', instance.name),
            _Divider(),
            _Row('Instance ID', instance.instanceId),
            _Divider(),
            _Row('创建时间', DateFormat('yyyy-MM-dd HH:mm').format(instance.createdAt)),
          ],
        ),
        const SizedBox(height: 16),
        _Card(
          title: 'PocketBase 信息',
          icon: Icons.cloud,
          children: [
            _Row('Record ID', instance.id),
            _Divider(),
            _Row('在线状态', instance.isOnline ? '🟢 在线' : '⚪ 离线'),
            _Divider(),
            _Row('注册频道', instance.onlineChannels.isNotEmpty ? instance.onlineChannels.join(', ') : '无'),
            if (instance.version.isNotEmpty) ...[
              _Divider(),
              _Row('OpenClaw 版本', instance.version),
            ],
          ],
        ),
      ],
    );
  }
}

// ─── Shared Widgets ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Card({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(height: 1);
}
