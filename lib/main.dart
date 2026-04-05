import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/datasources/pocketbase_datasource.dart';
import 'data/datasources/relay_api_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/instance_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/instance_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/instance_provider.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/theme/app_theme.dart';

void main() {
  runApp(const OcAdminApp());
}

class OcAdminApp extends StatelessWidget {
  const OcAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Data sources
    final pbDataSource = PocketBaseDataSource();
    final relayDataSource = RelayApiDataSource();

    // Repositories
    final authRepository = AuthRepositoryImpl(pbDataSource);
    final instanceRepository = InstanceRepositoryImpl(pbDataSource, relayDataSource);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository)..checkAuth(),
        ),
        ChangeNotifierProvider(
          create: (_) => InstanceProvider(instanceRepository),
        ),
      ],
      child: MaterialApp(
        title: 'OpenClaw Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const _AuthWrapper(),
      ),
    );
  }
}

class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        switch (authProvider.status) {
          case AuthStatus.initial:
          case AuthStatus.loading:
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pets, size: 64, color: Colors.deepPurple),
                    SizedBox(height: 24),
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('加载中...'),
                  ],
                ),
              ),
            );
          case AuthStatus.authenticated:
            return const HomePage();
          case AuthStatus.unauthenticated:
          case AuthStatus.error:
            return const LoginPage();
        }
      },
    );
  }
}
