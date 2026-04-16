import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Firebase 初期化の直後に呼ぶ。
///
/// `prod` のみ本番プロバイダ。`dev` / `stg` は常に Debug（エミュレータ・
/// profile ビルドでも Play Integrity に落ちないようにする）。
Future<void> bootstrapAppCheck(FirebaseApp app) async {
  final useDebugProviders = AppConfig.instance.flavor != Flavor.prod;

  await FirebaseAppCheck.instanceFor(app: app).activate(
    androidProvider:
        useDebugProviders ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider:
        useDebugProviders ? AppleProvider.debug : AppleProvider.appAttest,
  );

  if (useDebugProviders && kDebugMode) {
    debugPrint(
      'App Check: Debug プロバイダを有効化しました。'
      'Logcat の debug secret を Firebase Console（同一プロジェクト）の '
      'App Check → Android アプリ → デバッグトークンに登録してください。',
    );
  }
}
