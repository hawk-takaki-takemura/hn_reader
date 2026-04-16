import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'core/config/app_config.dart';
import 'core/config/firebase/dev_firebase_options.dart' as dev_fb;
import 'core/firebase/app_check_bootstrap.dart';
import 'core/firebase/auth_bootstrap.dart';
import 'core/remote_config/remote_config_bootstrap.dart';
import 'main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.initialize(
    const AppConfig(
      flavor: Flavor.dev,
      appName: 'Yomi Dev',
    ),
  );

  final app = await Firebase.initializeApp(
    name: 'dev',
    options: dev_fb.DefaultFirebaseOptions.currentPlatform,
  );

  await bootstrapAppCheck(app);
  await bootstrapRemoteConfig(app);
  await ensureSignedInForFirestore(app);

  await MobileAds.instance.initialize();

  runApp(
    const ProviderScope(child: App()),
  );
}
