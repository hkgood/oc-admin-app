import 'package:flutter/material.dart';
import '../../domain/entities/instance.dart';

class InstanceCard extends StatelessWidget {
  final Instance instance;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const InstanceCard({
    super.key,
    required this.instance,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Online status dot
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: instance.isOnline ? Colors.green : Colors.grey,
                      boxShadow: instance.isOnline
                          ? [BoxShadow(color: Colors.green.withAlpha(100), blurRadius: 6)]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      instance.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                        size: 20,
                      ),
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                instance.instanceId,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                      fontFamily: 'monospace',
                    ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MetricChip(
                    icon: Icons.memory,
                    label: 'CPU',
                    value: '${instance.cpuUsage.toStringAsFixed(1)}%',
                    color: _cpuColor(instance.cpuUsage),
                  ),
                  const SizedBox(width: 8),
                  _MetricChip(
                    icon: Icons.storage,
                    label: '内存',
                    value: '${instance.memoryUsage.toStringAsFixed(1)}%',
                    color: _memoryColor(instance.memoryUsage),
                  ),
                  const Spacer(),
                  if (instance.isOnline)
                    _MetricChip(
                      icon: Icons.timer,
                      label: '运行',
                      value: instance.uptimeFormatted,
                      color: colorScheme.primary,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '离线',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              if (instance.processes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: instance.processes.take(3).map((p) {
                    return Chip(
                      label: Text(
                        p.channel,
                        style: const TextStyle(fontSize: 10),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
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

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
