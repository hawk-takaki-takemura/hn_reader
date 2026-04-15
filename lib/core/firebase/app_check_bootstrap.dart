import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase 初期化の直後に呼ぶ。
Future<void> bootstrapAppCheck(FirebaseApp app) async {
  await FirebaseAppCheck.instanceFor(app: app).activate(
    androidProvider:
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider:
        kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
  );
}
