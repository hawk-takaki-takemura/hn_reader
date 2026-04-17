class AppConstants {
  AppConstants._();

  // キャッシュ
  static const Duration cacheExpiration = Duration(minutes: 30);
  static const String storyCacheBox = 'story_cache';

  // 翻訳
  static const int freeSummaryLimit = 3;

  /// ストア審査向け: AI 生成（要約・傾向など）の不適切内容を報告する宛先。
  /// 空のときはメール起動せず、記事 ID のコピーなどのみ案内する。
  static const String aiContentReportEmail = '';
}
