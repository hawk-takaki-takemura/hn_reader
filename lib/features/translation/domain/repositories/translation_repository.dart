import '../entities/translation.dart';

abstract class TranslationRepository {
  // キャッシュから取得
  Future<Translation?> getCachedTranslation(int storyId);

  // Claude APIで翻訳してキャッシュに保存
  Future<Translation> translate(int storyId, String title);

  // 複数記事を一括翻訳
  Future<List<Translation>> translateBatch(
    Map<int, String> stories,
  );
}
