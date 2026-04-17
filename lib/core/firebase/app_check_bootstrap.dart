import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Firebase 初期化の直後に呼ぶ。
///
/// **Android / iOS の本番アテステーション**（Play Integrity / App Attest）は
/// `prod` かつ **リリースビルド**（`kReleaseMode`）のときだけ有効にする。
///
/// `prod` でも `flutter run`（デバッグ）やエミュレータでは Debug プロバイダにし、
/// そうしないと Play Integrity が 403（App attestation failed）になりやすい。
/// `dev` / `stg` は常に Debug。
Future<void> bootstrapAppCheck(FirebaseApp app) async {
  final flavor = AppConfig.instance.flavor;
  final useProductionAttestation = flavor == Flavor.prod && kReleaseMode;

  final androidProvider =
      useProductionAttestation ? AndroidProvider.playIntegrity : AndroidProvider.debug;
  final appleProvider =
      useProductionAttestation ? AppleProvider.appAttest : AppleProvider.debug;

  await FirebaseAppCheck.instanceFor(app: app).activate(
    androidProvider: androidProvider,
    appleProvider: appleProvider,
  );

  if (!useProductionAttestation && kDebugMode) {
    debugPrint(
      'App Check: Debug プロバイダを有効化しました（flavor=$flavor）。'
      'Logcat の debug secret を Firebase Console（同一プロジェクト）の '
      'App Check → アプリ → デバッグトークンに登録してください。',
    );
  }
}
