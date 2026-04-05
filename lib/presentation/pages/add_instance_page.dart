import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/instance_provider.dart';

class AddInstancePage extends StatefulWidget {
  const AddInstancePage({super.key});

  @override
  State<AddInstancePage> createState() => _AddInstancePageState();
}

class _AddInstancePageState extends State<AddInstancePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _instanceIdController = TextEditingController();
  final _instanceTokenController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _instanceIdController.dispose();
    _instanceTokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await context.read<InstanceProvider>().addInstance(
            _nameController.text.trim(),
            _instanceIdController.text.trim(),
            _instanceTokenController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('实例添加成功')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _errorMessage = '添加失败：${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加实例'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '绑定 WatchClaw 实例',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '在 WatchClaw 设备上运行 watch-claw 插件，获取 Instance ID 和 Token 后填入下方',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Instance name
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: '实例名称',
                  hintText: '例如：我的服务器',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return '请输入实例名称';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Instance ID
              TextFormField(
                controller: _instanceIdController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Instance ID',
                  hintText: 'watch-claw 显示的 instance_id',
                  prefixIcon: Icon(Icons.fingerprint),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return '请输入 Instance ID';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Instance Token
              TextFormField(
                controller: _instanceTokenController,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Instance Token',
                  hintText: 'watch-claw 显示的 instance_token',
                  prefixIcon: Icon(Icons.key),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return '请输入 Instance Token';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Submit button
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('添加实例'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
