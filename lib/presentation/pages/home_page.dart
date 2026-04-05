import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/instance_provider.dart';
import '../widgets/instance_card.dart';
import 'add_instance_page.dart';
import 'instance_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InstanceProvider>().loadInstances();
      context.read<InstanceProvider>().startAutoRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenClaw'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<InstanceProvider>().loadInstances();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboard(),
          _buildInstancesTab(),
          _buildSettingsTab(),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddInstancePage(),
                  ),
                );
                if (result == true && mounted) {
                  context.read<InstanceProvider>().loadInstances();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('添加实例'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '概览',
          ),
          NavigationDestination(
            icon: Icon(Icons.dns_outlined),
            selectedIcon: Icon(Icons.dns),
            label: '实例',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Consumer<InstanceProvider>(
      builder: (context, provider, _) {
        if (provider.status == InstanceStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final total = provider.instances.length;
        final online = provider.onlineInstances.length;
        final offline = provider.offlineInstances.length;

        return RefreshIndicator(
          onRefresh: provider.loadInstances,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status summary cards
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: '总计',
                      value: '$total',
                      icon: Icons.dns,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: '在线',
                      value: '$online',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: '离线',
                      value: '$offline',
                      icon: Icons.cancel,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (provider.onlineInstances.isNotEmpty) ...[
                Text(
                  '在线实例',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ...provider.onlineInstances.map(
                  (instance) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InstanceCard(
                      instance: instance,
                      onTap: () => _openInstanceDetail(instance.instanceId),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (provider.offlineInstances.isNotEmpty) ...[
                Text(
                  '离线实例',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ...provider.offlineInstances.map(
                  (instance) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InstanceCard(
                      instance: instance,
                      onTap: () => _openInstanceDetail(instance.instanceId),
                    ),
                  ),
                ),
              ],

              if (provider.instances.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.dns_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无绑定实例',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '点击下方"添加实例"绑定你的 OpenClaw',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstancesTab() {
    return Consumer<InstanceProvider>(
      builder: (context, provider, _) {
        if (provider.status == InstanceStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.instances.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.dns_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无绑定实例',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '点击右上角 + 添加实例',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: provider.loadInstances,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.instances.length,
            itemBuilder: (context, index) {
              final instance = provider.instances[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InstanceCard(
                  instance: instance,
                  onTap: () => _openInstanceDetail(instance.instanceId),
                  onDelete: () => _confirmDelete(instance),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            (authProvider.user?.email.substring(0, 1).toUpperCase() ?? 'U'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authProvider.user?.name ?? '用户',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                authProvider.user?.email ?? '',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('退出登录'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('退出登录'),
                    content: const Text('确定要退出登录吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.read<AuthProvider>().logout();
                        },
                        child: const Text('退出'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _openInstanceDetail(String instanceId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InstanceDetailPage(instanceId: instanceId),
      ),
    );
  }

  void _confirmDelete(dynamic instance) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除实例'),
        content: Text('确定要删除 "${instance.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<InstanceProvider>().removeInstance(instance.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('实例已删除')),
                );
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
