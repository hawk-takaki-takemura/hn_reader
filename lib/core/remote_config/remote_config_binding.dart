import 'package:firebase_remote_config/firebase_remote_config.dart';

/// [bootstrapRemoteConfig] 完了後に参照する。
class RemoteConfigBinding {
  RemoteConfigBinding._();

  static FirebaseRemoteConfig? _instance;

  static FirebaseRemoteConfig get instance {
    final i = _instance;
    if (i == null) {
      throw StateError(
        'Remote Config が未初期化です。main_dev.dart / main_stg.dart / main_prod.dart で '
        'bootstrapRemoteConfig を呼び出してください。',
      );
    }
    return i;
  }

  static void attach(FirebaseRemoteConfig remoteConfig) {
    _instance = remoteConfig;
  }
}
