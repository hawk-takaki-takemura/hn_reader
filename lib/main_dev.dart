import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/config/firebase/dev_firebase_options.dart' as dev_fb;
import 'main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.initialize(
    const AppConfig(
      flavor: Flavor.dev,
      appName: 'HN Reader Dev',
    ),
  );

  await Firebase.initializeApp(
    options: dev_fb.DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(child: App()),
  );
}
