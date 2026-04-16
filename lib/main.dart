import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/feed/presentation/screens/feed_screen.dart';
import 'features/feed/presentation/screens/story_detail_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.instance.appName,
      routerConfig: _router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
    );
  }
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const FeedScreen(),
    ),
    GoRoute(
      path: '/story',
      builder: (context, state) {
        final story = state.extra;
        if (story is! StoryDetailArgs) {
          return const FeedScreen();
        }
        return StoryDetailScreen(args: story);
      },
    ),
  ],
);
