class Secrets {
  Secrets._();

  // Claude API Key
  static const String claudeApiKey =
      String.fromEnvironment('CLAUDE_API_KEY', defaultValue: '');

  // AdMob App IDs
  static const String admobAppIdAndroid =
      String.fromEnvironment('ADMOB_APP_ID_ANDROID', defaultValue: '');
  static const String admobAppIdIos =
      String.fromEnvironment('ADMOB_APP_ID_IOS', defaultValue: '');

  // AdMob Unit IDs - Android
  static const String admobAndroidBanner =
      String.fromEnvironment('ADMOB_ANDROID_BANNER', defaultValue: '');
  static const String admobAndroidNative =
      String.fromEnvironment('ADMOB_ANDROID_NATIVE', defaultValue: '');

  // AdMob Unit IDs - iOS
  static const String admobIosBanner =
      String.fromEnvironment('ADMOB_IOS_BANNER', defaultValue: '');
  static const String admobIosNative =
      String.fromEnvironment('ADMOB_IOS_NATIVE', defaultValue: '');
}
