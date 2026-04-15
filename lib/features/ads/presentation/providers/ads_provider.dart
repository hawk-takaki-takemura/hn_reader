import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';

/// 広告表示可否
/// - dev: 常にfalse（広告非表示）
/// - stg/prod: true（将来的にRemote Config・サブスク判定を追加）
final adsEnabledProvider = Provider<bool>((ref) {
  final flavor = AppConfig.instance.flavor;

  // devは広告表示しない
  if (flavor == Flavor.dev) return false;

  // TODO: Remote Config連携（ads_enabled）
  // TODO: サブスク加入者はfalse（RevenueCat連携時に追加）
  return true;
});

/// ネイティブ広告の差し込み間隔
final nativeAdIntervalProvider = Provider<int>((ref) {
  // TODO: Remote Config連携
  return 10;
});
