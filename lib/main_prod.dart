import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/config/firebase/prod_firebase_options.dart' as prod_fb;
import 'main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.initialize(
    const AppConfig(
      flavor: Flavor.prod,
      appName: 'HN Reader',
    ),
  );

  await Firebase.initializeApp(
    options: prod_fb.DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(child: App()),
  );
}
