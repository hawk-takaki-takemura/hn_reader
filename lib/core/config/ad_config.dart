import 'dart:io';

import 'package:flutter/foundation.dart';

import 'secrets.dart';

class AdConfig {
  AdConfig._();

  /// Google のデモ用アプリ向けテストユニット（本番 ID と入れ替えないこと）
  static const _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _testNative = 'ca-app-pub-3940256099942544/2247696110';

  static String get bannerAdUnitId {
    if (Platform.isIOS) {
      return _resolveUnitId(Secrets.admobIosBanner, _testBanner, 'ADMOB_IOS_BANNER');
    }
    if (Platform.isAndroid) {
      return _resolveUnitId(
        Secrets.admobAndroidBanner,
        _testBanner,
        'ADMOB_ANDROID_BANNER',
      );
    }
    return '';
  }

  static String get nativeAdUnitId {
    if (Platform.isIOS) {
      return _resolveUnitId(Secrets.admobIosNative, _testNative, 'ADMOB_IOS_NATIVE');
    }
    if (Platform.isAndroid) {
      return _resolveUnitId(
        Secrets.admobAndroidNative,
        _testNative,
        'ADMOB_ANDROID_NATIVE',
      );
    }
    return '';
  }

  /// `--dart-define` / `.env` 経由で値があるときはそれを使う。
  /// 空のままだと [kDebugMode] では公式テスト ID にフォールバック（エミュで広告確認用）。
  /// リリースでは未設定を許さない（誤ってテスト広告を出さないため）。
  static String _resolveUnitId(
    String fromEnvironment,
    String testFallback,
    String dartDefineKey,
  ) {
    final id = fromEnvironment.trim();
    if (id.isNotEmpty) return id;
    if (kDebugMode) return testFallback;
    throw StateError(
      'AdMob ad unit is empty. Set $dartDefineKey via --dart-define or '
      '--dart-define-from-file (e.g. Makefile / CI).',
    );
  }

  /// 明示的にテスト IDだけ使いたい場合
  static String get testBannerAdUnitId => _testBanner;
  static String get testNativeAdUnitId => _testNative;
}
