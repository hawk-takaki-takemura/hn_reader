import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'remote_config_binding.dart';

/// Firebase 初期化の直後に呼ぶ。
Future<void> bootstrapRemoteConfig(FirebaseApp app) async {
  final rc = FirebaseRemoteConfig.instanceFor(app: app);
  final flavor = AppConfig.instance.flavor;

  final minInterval = flavor == Flavor.dev
      ? Duration.zero
      : const Duration(minutes: 5);

  await rc.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: minInterval,
    ),
  );

  await rc.setDefaults(<String, dynamic>{
    'translation_backend': 'remote',
    'translation_enabled': true,
    'ads_enabled': flavor != Flavor.dev,
    'maintenance_mode': false,
    'native_ad_interval': 10,
    'free_summary_limit': 3,
  });

  try {
    await rc.fetchAndActivate();
  } catch (e, st) {
    debugPrint('Remote Config fetch failed: $e');
    debugPrint('$st');
  }

  RemoteConfigBinding.attach(rc);
}
