import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../feed/domain/entities/story.dart';
import '../../data/datasources/claude_api_datasource.dart';
import '../../data/datasources/translation_cache_datasource.dart';
import '../../data/repositories/translation_repository_impl.dart';
import '../../domain/repositories/translation_repository.dart';

// ---- DI ----

final claudeApiDataSourceProvider = Provider<ClaudeApiDataSource>((ref) {
  return ClaudeApiDataSourceImpl();
});

final translationCacheDataSourceProvider =
    Provider<TranslationCacheDataSource>((ref) {
  final app = Firebase.app(AppConfig.instance.flavor.name);
  return TranslationCacheDataSourceImpl(
    firestore: FirebaseFirestore.instanceFor(app: app),
  );
});

final translationRepositoryProvider =
    Provider<TranslationRepository>((ref) {
  return TranslationRepositoryImpl(
    claudeApi: ref.watch(claudeApiDataSourceProvider),
    cache: ref.watch(translationCacheDataSourceProvider),
  );
});

// ---- State ----

final translationEnabledProvider = StateProvider<bool>((ref) => true);

final translatedStoriesProvider =
    FutureProvider.family<List<Story>, List<Story>>((ref, stories) async {
  final enabled = ref.watch(translationEnabledProvider);

  debugPrint('=== translation enabled: $enabled');
  debugPrint('=== stories count: ${stories.length}');

  if (!enabled) return stories;

  final repository = ref.read(translationRepositoryProvider);

  final needTranslation = <int, String>{};
  for (final story in stories) {
    if (story.titleJa == null) {
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
      for (final t in translations) t.storyId: t.titleJa
    };

    return stories.map((story) {
      final titleJa = translationMap[story.id];
      if (titleJa == null) return story;
      return _StoryWithTranslation(story, titleJa);
    }).toList();
  } catch (e, st) {
    debugPrint('=== translation error: $e');
    debugPrint('=== translation stack: $st');
    return stories;
  }
});

class _StoryWithTranslation extends Story {
  _StoryWithTranslation(Story story, String titleJa)
      : super(
          id: story.id,
          title: story.title,
          titleJa: titleJa,
          url: story.url,
          by: story.by,
          score: story.score,
          descendants: story.descendants,
          time: story.time,
          type: story.type,
        );
}
