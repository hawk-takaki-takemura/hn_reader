import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_config.dart';
import 'features/feed/presentation/screens/feed_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.instance.appName,
      routerConfig: _router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
    );
  }
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const FeedScreen(),
    ),
  ],
);
