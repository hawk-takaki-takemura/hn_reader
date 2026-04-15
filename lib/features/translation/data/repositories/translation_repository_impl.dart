import '../../domain/entities/translation.dart';
import '../../domain/repositories/translation_repository.dart';
import '../datasources/claude_api_datasource.dart';
import '../datasources/translation_cache_datasource.dart';
import '../models/translation_model.dart';

class TranslationRepositoryImpl implements TranslationRepository {
  final ClaudeApiDataSource _claudeApi;
  final TranslationCacheDataSource _cache;

  TranslationRepositoryImpl({
    required ClaudeApiDataSource claudeApi,
    required TranslationCacheDataSource cache,
  }) : _claudeApi = claudeApi,
       _cache = cache;

  @override
  Future<Translation?> getCachedTranslation(int storyId) async {
    final cached = await _cache.getTranslation(storyId);
    if (cached == null || cached.isExpired) return null;
    return cached;
  }

  @override
  Future<Translation> translate(int storyId, String title) async {
    final cached = await getCachedTranslation(storyId);
    if (cached != null) return cached;

    final titleJa = await _claudeApi.translateTitle(title);
    final translation = TranslationModel(
      storyId: storyId,
      titleJa: titleJa,
      cachedAt: DateTime.now(),
    );

    await _cache.saveTranslation(translation);
    return translation;
  }

  @override
  Future<List<Translation>> translateBatch(
    Map<int, String> stories,
  ) async {
    final cached =
        await _cache.getTranslations(stories.keys.toList());

    final needTranslation = <int, String>{};
    for (final entry in stories.entries) {
      final cachedItem = cached[entry.key];
      if (cachedItem == null || cachedItem.isExpired) {
        needTranslation[entry.key] = entry.value;
      }
    }

    if (needTranslation.isNotEmpty) {
      final translated =
          await _claudeApi.translateTitles(needTranslation);

      for (final entry in translated.entries) {
        final model = TranslationModel(
          storyId: entry.key,
          titleJa: entry.value,
          cachedAt: DateTime.now(),
        );
        await _cache.saveTranslation(model);
        cached[entry.key] = model;
      }
    }

    return cached.values.toList();
  }
}
