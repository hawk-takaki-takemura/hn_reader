import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/remote_config/remote_config_providers.dart';
import '../../../../core/utils/locale_utils.dart';
import '../../../feed/domain/entities/story.dart';
import '../../data/datasources/translation_data_source.dart';
import '../../data/datasources/translation_noop_data_source.dart';
import '../../data/datasources/translation_remote_data_source.dart';
import '../../data/repositories/translation_repository_impl.dart';
import '../../domain/repositories/translation_repository.dart';

// ---- DI ----

final translationDataSourceProvider = Provider<TranslationDataSource>((ref) {
  if (ref.watch(translationBackendProvider) != 'remote') {
    return const TranslationNoopDataSource();
  }
  return TranslationRemoteDataSource();
});

final translationRepositoryProvider =
    Provider<TranslationRepository>((ref) {
  return TranslationRepositoryImpl(
    remote: ref.watch(translationDataSourceProvider),
  );
});

// ---- State ----

final translationEnabledProvider = StateProvider<bool>((ref) => true);

final translatedStoriesProvider =
    FutureProvider.family<List<Story>, List<Story>>((ref, stories) async {
  final enabled = ref.watch(translationEnabledProvider);

  debugPrint('=== translation enabled: $enabled');
  debugPrint('=== stories count: ${stories.length}');
  debugPrint(
    '=== translation locale: lang=${LocaleUtils.deviceLanguageCode} '
    'needsTranslation=${LocaleUtils.needsTranslation}',
  );

  if (!LocaleUtils.needsTranslation) {
    debugPrint(
      '=== translation skipped: English UI does not request title translation '
      '(set emulator language to ja etc. to test Callable + App Check)',
    );
    return stories;
  }

  if (!enabled) return stories;

  final repository = ref.read(translationRepositoryProvider);

  final needTranslation = <int, String>{};
  for (final story in stories) {
    if (story.translatedTitle == null) {
      needTranslation[story.id] = story.title;
    }
  }

  debugPrint('=== needTranslation count: ${needTranslation.length}');

  if (needTranslation.isEmpty) return stories;

  try {
    final translations =
        await repository.translateBatch(needTranslation);
    debugPrint('=== translated count: ${translations.length}');

    final translationMap = {
      for (final t in translations) t.storyId: t.translatedTitle
    };

    return stories.map((story) {
      final translatedTitle = translationMap[story.id];
      if (translatedTitle == null) return story;
      return _StoryWithTranslation(story, translatedTitle);
    }).toList();
  } catch (e, st) {
    debugPrint('=== translation error: $e');
    debugPrint('=== translation stack: $st');
    return stories;
  }
});

class _StoryWithTranslation extends Story {
  _StoryWithTranslation(Story story, String translatedTitle)
      : super(
          id: story.id,
          title: story.title,
          translatedTitle: translatedTitle,
          url: story.url,
          by: story.by,
          score: story.score,
          descendants: story.descendants,
          time: story.time,
          type: story.type,
          enrichStatus: story.enrichStatus,
          enrichment: story.enrichment,
        );
}
