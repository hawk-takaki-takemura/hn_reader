import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'core/config/app_config.dart';
import 'core/config/firebase/stg_firebase_options.dart' as stg_fb;
import 'main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.initialize(
    const AppConfig(
      flavor: Flavor.stg,
      appName: 'Yomi Stg',
    ),
  );

  await Firebase.initializeApp(
    name: 'stg',
    options: stg_fb.DefaultFirebaseOptions.currentPlatform,
  );

  await MobileAds.instance.initialize();

  runApp(
    const ProviderScope(child: App()),
  );
}
