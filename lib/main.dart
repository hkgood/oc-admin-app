import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  WidgetsFlutterBinding.ensureInitialized();
  // Make status bar transparent and match app background
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
  ));
  runApp(const WatchClawApp());
}

class WatchClawApp extends StatelessWidget {
  const WatchClawApp({super.key});

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
        title: 'WatchClaw',
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
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'WatchClaw',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w300,
                            letterSpacing: 4,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
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
