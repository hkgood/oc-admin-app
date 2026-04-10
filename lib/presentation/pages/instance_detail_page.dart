import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
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

  @override
  Widget build(BuildContext context) {
    return Consumer<InstanceProvider>(
      builder: (context, provider, _) {
        final instance = provider.instances.firstWhere(
          (i) => i.instanceId == widget.instanceId,
          orElse: () => Instance(
            id: '',
            name: 'Unknown',
            instanceId: widget.instanceId,
            instanceToken: '',
            createdAt: DateTime.now(),
          ),
        );

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  surfaceTintColor: Colors.transparent,
                  iconTheme: IconThemeData(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Text(
                      instance.name,
                      style: const TextStyle(fontSize: 15),
                    ),
                    background: _InstanceHeader(instance: instance),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: '🔋 系统'),
                        Tab(text: '🤖 运行'),
                        Tab(text: '📋 进程'),
                        Tab(text: 'ℹ️ 实例'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
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
        );
      },
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────

class _InstanceHeader extends StatelessWidget {
  final Instance instance;

  const _InstanceHeader({required this.instance});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.tertiary,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 56),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatusBadge(isOnline: instance.isOnline, thinking: instance.thinking),
                  const SizedBox(width: 8),
                  Text(
                    _statusText(instance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // CPU + Memory + Uptime
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _HeaderMetric(
                    icon: Icons.memory,
                    label: 'CPU',
                    value: '${instance.cpuUsage.toStringAsFixed(1)}%',
                    color: _cpuColor(instance.cpuUsage),
                  ),
                  _HeaderMetric(
                    icon: Icons.storage,
                    label: '内存',
                    value: '${instance.memoryUsage.toStringAsFixed(1)}%',
                    color: _memoryColor(instance.memoryUsage),
                  ),
                  _HeaderMetric(
                    icon: Icons.timer,
                    label: '运行时长',
                    value: instance.uptimeFormatted,
                    color: Colors.white70,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusText(Instance i) {
    if (!i.isOnline) return '离线';
    if (i.thinking) return '思考中…';
    return '在线';
  }

  Color _cpuColor(double v) {
    if (v < 50) return Colors.greenAccent;
    if (v < 80) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Color _memoryColor(double v) {
    if (v < 60) return Colors.lightBlueAccent;
    if (v < 85) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}

class _HeaderMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HeaderMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isOnline;
  final bool thinking;

  const _StatusBadge({required this.isOnline, required this.thinking});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (!isOnline) {
      color = Colors.grey;
    } else if (thinking) {
      color = Colors.orangeAccent;
    } else {
      color = Colors.greenAccent;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: isOnline
            ? [BoxShadow(color: color.withAlpha(180), blurRadius: 8)]
            : null,
      ),
    );
  }
}

// ─── Tab 1: System ───────────────────────────────────────────────────────────

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
            Expanded(child: _GaugeCard(
              label: 'CPU',
              value: instance.cpuUsage,
              icon: Icons.memory,
              color: _cpuColor(instance.cpuUsage),
              suffix: '%',
            )),
            const SizedBox(width: 12),
            Expanded(child: _GaugeCard(
              label: '内存',
              value: instance.memoryUsage,
              icon: Icons.storage,
              color: _memoryColor(instance.memoryUsage),
              suffix: '%',
            )),
          ],
        ),
        const SizedBox(height: 16),

        // System info card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(icon: Icons.widgets, title: '系统信息'),
                const SizedBox(height: 12),
                _InfoRow(label: '运行时长', value: instance.uptimeFormatted),
                const Divider(height: 1),
                _InfoRow(
                  label: '最后活跃',
                  value: instance.lastSeen != null
                      ? DateFormat('yyyy-MM-dd HH:mm:ss').format(instance.lastSeen!)
                      : '未知',
                ),
                const Divider(height: 1),
                _InfoRow(
                  label: '最后消息',
                  value: instance.lastMessageAgo > 0
                      ? '${instance.lastMessageAgoFormatted} 前'
                      : '无',
                ),
                const Divider(height: 1),
                _InfoRow(
                  label: 'OpenClaw 版本',
                  value: instance.version.isNotEmpty ? instance.version : '未知',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Resource mini chart (visual only, since we don't have history)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(icon: Icons.show_chart, title: '资源使用'),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: Row(
                    children: [
                      Expanded(
                        child: _MiniBar(
                          label: 'CPU',
                          value: instance.cpuUsage / 100,
                          color: _cpuColor(instance.cpuUsage),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MiniBar(
                          label: '内存',
                          value: instance.memoryUsage / 100,
                          color: _memoryColor(instance.memoryUsage),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
  final IconData icon;
  final Color color;
  final String suffix;

  const _GaugeCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
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
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${value.toStringAsFixed(1)}$suffix',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
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

// ─── Tab 2: Runtime ─────────────────────────────────────────────────────────

class _RuntimeTab extends StatelessWidget {
  final Instance instance;

  const _RuntimeTab({required this.instance});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Current state
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(icon: Icons.smart_toy, title: '当前状态'),
                const SizedBox(height: 12),
                _InfoRow(label: '当前模型', value: instance.currentModel.isNotEmpty ? instance.currentModel : '未设置'),
                const Divider(height: 1),
                _InfoRow(label: '当前 Agent', value: instance.currentAgent.isNotEmpty ? instance.currentAgent : '未设置'),
                const Divider(height: 1),
                _InfoRow(
                  label: '活跃频道',
                  value: instance.onlineChannels.isNotEmpty
                      ? instance.onlineChannels.join(', ')
                      : '无',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Statistics
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(icon: Icons.bar_chart, title: '统计数据'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _StatCard(icon: Icons.chat_bubble, label: '会话', value: '${instance.sessionCount}', color: Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(icon: Icons.cable, label: '频道', value: '${instance.channelCount}', color: Colors.purple)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(icon: Icons.device_hub, label: '节点', value: '${instance.nodeCount}', color: Colors.teal)),
                  ],
                ),
                const SizedBox(height: 16),
                _StatCard(icon: Icons.token, label: '累计 Token', value: instance.tokenUsageFormatted, color: Colors.amber, wide: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Thinking indicator
        if (instance.thinking)
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.orange),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI 正在思考…',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                        Text(
                          '模型: ${instance.currentModel}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool wide;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    if (wide) {
      return Card(
        color: color.withAlpha(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: color)),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: color.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 3: Info ─────────────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  final Instance instance;

  const _InfoTab({required this.instance});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(icon: Icons.info_outline, title: '基本信息'),
                const SizedBox(height: 12),
                _DetailRow(label: '名称', value: instance.name),
                const Divider(height: 1),
                _DetailRow(label: 'Instance ID', value: instance.instanceId),
                const Divider(height: 1),
                _DetailRow(
                  label: '创建时间',
                  value: DateFormat('yyyy-MM-dd HH:mm').format(instance.createdAt),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(icon: Icons.cloud, title: 'PocketBase 信息'),
                const SizedBox(height: 12),
                _DetailRow(label: 'Record ID', value: instance.id),
                const Divider(height: 1),
                _DetailRow(label: '在线状态', value: instance.isOnline ? '🟢 在线' : '⚪ 离线'),
                const Divider(height: 1),
                _DetailRow(label: '注册频道', value: instance.onlineChannels.isNotEmpty ? instance.onlineChannels.join(', ') : '无'),
                if (instance.version.isNotEmpty) ...[
                  const Divider(height: 1),
                  _DetailRow(label: 'OpenClaw 版本', value: instance.version),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Shared Components ────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MiniBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: value.clamp(0.02, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
        ),
        Text(
          '${(value * 100).toStringAsFixed(1)}%',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

// ─── Process Tab (kept but uses instance.processes now) ─────────────────────

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
            Icon(
              Icons.list,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无进程信息',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '进程信息由 watch-claw 插件定期上报',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
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
                child: Icon(
                  Icons.smart_toy,
                  color: _statusColor(p.status),
                  size: 20,
                ),
              ),
              title: Text(p.agent.isEmpty ? p.channel : p.agent),
              subtitle: Text('Channel: ${p.channel}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(p.status).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p.status,
                  style: TextStyle(
                    color: _statusColor(p.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'running':
        return Colors.green;
      case 'idle':
        return Colors.blue;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// ─── Tab Bar Delegate ────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
