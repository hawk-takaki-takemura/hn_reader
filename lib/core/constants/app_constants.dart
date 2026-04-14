class AppConstants {
  AppConstants._();

  // キャッシュ
  static const Duration cacheExpiration = Duration(minutes: 30);
  static const String storyCacheBox = 'story_cache';

  // 翻訳
  static const int freeSummaryLimit = 3;
}
