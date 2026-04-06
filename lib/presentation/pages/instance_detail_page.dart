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
    _tabController = TabController(length: 3, vsync: this);
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
                  expandedHeight: 200,
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
                      style: const TextStyle(fontSize: 16),
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
                        Tab(text: '状态'),
                        Tab(text: '进程'),
                        Tab(text: '信息'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _StatusTab(instance: instance),
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
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatusBadge(isOnline: instance.isOnline),
                  const SizedBox(width: 8),
                  Text(
                    instance.isOnline ? '在线' : '离线',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _HeaderMetric(
                    label: 'CPU',
                    value: '${instance.cpuUsage.toStringAsFixed(1)}%',
                  ),
                  _HeaderMetric(
                    label: '内存',
                    value: '${instance.memoryUsage.toStringAsFixed(1)}%',
                  ),
                  _HeaderMetric(
                    label: '运行时长',
                    value: instance.uptimeFormatted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isOnline;

  const _StatusBadge({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? Colors.greenAccent : Colors.grey,
        boxShadow: isOnline
            ? [BoxShadow(color: Colors.greenAccent.withAlpha(150), blurRadius: 8)]
            : null,
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  final Instance instance;

  const _StatusTab({required this.instance});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // CPU & Memory gauges
        Row(
          children: [
            Expanded(
              child: _GaugeCard(
                label: 'CPU 使用率',
                value: instance.cpuUsage,
                color: _cpuColor(instance.cpuUsage),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GaugeCard(
                label: '内存使用率',
                value: instance.memoryUsage,
                color: _memoryColor(instance.memoryUsage),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Uptime card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '运行信息',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _InfoRow(label: '运行时长', value: instance.uptimeFormatted),
                const Divider(),
                _InfoRow(
                  label: '最后活跃',
                  value: instance.lastSeen != null
                      ? DateFormat('yyyy-MM-dd HH:mm:ss').format(instance.lastSeen!)
                      : '未知',
                ),
                const Divider(),
                _InfoRow(
                  label: '在线状态',
                  value: instance.isOnline ? '🟢 在线' : '⚪ 离线',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Mini charts
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '资源趋势',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: _MiniLineChart(cpu: instance.cpuUsage, memory: instance.memoryUsage),
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
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: value / 100,
                      strokeWidth: 8,
                      backgroundColor: color.withAlpha(40),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                  Text(
                    '${value.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _MiniLineChart extends StatelessWidget {
  final double cpu;
  final double memory;

  const _MiniLineChart({required this.cpu, required this.memory});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: [FlSpot(0, cpu * 0.8), FlSpot(1, cpu), FlSpot(2, cpu * 1.05)],
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withAlpha(30),
            ),
          ),
          LineChartBarData(
            spots: [FlSpot(0, memory * 0.9), FlSpot(1, memory), FlSpot(2, memory * 1.02)],
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withAlpha(30),
            ),
          ),
        ],
      ),
    );
  }
}

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
                Text(
                  '基本信息',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _DetailRow(label: '名称', value: instance.name),
                const Divider(),
                _DetailRow(label: 'Instance ID', value: instance.instanceId),
                const Divider(),
                _DetailRow(
                  label: '创建时间',
                  value: DateFormat('yyyy-MM-dd HH:mm').format(instance.createdAt),
                ),
              ],
            ),
          ),
        ),
      ],
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
            width: 100,
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
