import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import 'email_verification_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      final errorMsg = authProvider.errorMessage ?? '';
      // Check if it's a verification issue
      if (errorMsg.contains('verified') || errorMsg.toLowerCase().contains('verification')) {
        _showVerificationDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg.isNotEmpty ? errorMsg : '登录失败'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('邮箱未验证'),
        content: const Text('你的邮箱尚未验证。请查收验证邮件并点击验证链接。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => EmailVerificationPage(
                    email: _emailController.text.trim(),
                    onVerified: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ),
              );
            },
            child: const Text('查看邮箱'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final authProvider = context.read<AuthProvider>();
              await authProvider.requestPasswordReset(_emailController.text.trim());
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('验证邮件已重新发送')),
              );
            },
            child: const Text('重新发送'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // WatchClaw text logo
                    Text(
                      'WatchClaw',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w200,
                            letterSpacing: 4,
                            color: colorScheme.primary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'OpenClaw 管理客户端',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            letterSpacing: 1,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: '邮箱',
                        hintText: 'your@email.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return '请输入邮箱';
                        if (!v.contains('@')) return '邮箱格式不正确';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: '密码',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return '请输入密码';
                        if (v.length < 6) return '密码至少6位';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    FilledButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('登录'),
                    ),
                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordPage(),
                            ),
                          );
                        },
                        child: const Text('忘记密码？'),
                      ),
                    ),
                    const SizedBox(height: 8),

                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        );
                      },
                      child: const Text('没有账号？注册'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
