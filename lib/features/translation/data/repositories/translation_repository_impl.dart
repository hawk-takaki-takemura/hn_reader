import '../../domain/entities/translation.dart';
import '../../domain/repositories/translation_repository.dart';
import '../datasources/translation_data_source.dart';

class TranslationRepositoryImpl implements TranslationRepository {
  final TranslationDataSource _remote;

  TranslationRepositoryImpl({
    required TranslationDataSource remote,
  }) : _remote = remote;

  @override
  Future<Translation?> getCachedTranslation(int storyId) async => null;

  @override
  Future<Translation> translate(int storyId, String title) async {
    final translatedTitle = await _remote.translateTitle(title);
    return Translation(
      storyId: storyId,
      translatedTitle: translatedTitle,
      cachedAt: DateTime.now(),
    );
  }

  @override
  Future<List<Translation>> translateBatch(
    Map<int, String> stories,
  ) async {
    final translated = await _remote.translateTitles(stories);
    final now = DateTime.now();
    return translated.entries
        .map(
          (entry) => Translation(
            storyId: entry.key,
            translatedTitle: entry.value,
            cachedAt: now,
          ),
        )
        .toList();
  }
}
