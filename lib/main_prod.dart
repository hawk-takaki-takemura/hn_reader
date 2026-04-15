import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'core/config/app_config.dart';
import 'core/config/firebase/prod_firebase_options.dart' as prod_fb;
import 'main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.initialize(
    const AppConfig(
      flavor: Flavor.prod,
      appName: 'Yomi',
    ),
  );

  await Firebase.initializeApp(
    name: 'prod',
    options: prod_fb.DefaultFirebaseOptions.currentPlatform,
  );

  await MobileAds.instance.initialize();

  runApp(
    const ProviderScope(child: App()),
  );
}
