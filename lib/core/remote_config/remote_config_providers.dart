import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'remote_config_binding.dart';

final firebaseRemoteConfigProvider = Provider<FirebaseRemoteConfig>((ref) {
  return RemoteConfigBinding.instance;
});

/// Remote Config キー `translation_backend`（`remote` | `local` 想定）。
/// `local` のときは Callable を呼ばず元タイトルのままにする。
final translationBackendProvider = Provider<String>((ref) {
  final raw =
      ref.watch(firebaseRemoteConfigProvider).getString('translation_backend');
  final v = raw.trim().toLowerCase();
  if (v.isEmpty) return 'remote';
  return v;
});
