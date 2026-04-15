import 'dart:io';

import 'secrets.dart';

class AdConfig {
  AdConfig._();

  // テスト用ID（開発時に使用）
  static const _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _testNative = 'ca-app-pub-3940256099942544/2247696110';

  static String get bannerAdUnitId {
    if (Platform.isAndroid) return Secrets.admobAndroidBanner;
    if (Platform.isIOS) return Secrets.admobIosBanner;
    return '';
  }

  static String get nativeAdUnitId {
    if (Platform.isAndroid) return Secrets.admobAndroidNative;
    if (Platform.isIOS) return Secrets.admobIosNative;
    return '';
  }

  // テストIDを使いたい場合（デバッグ用）
  static String get testBannerAdUnitId => _testBanner;
  static String get testNativeAdUnitId => _testNative;
}
