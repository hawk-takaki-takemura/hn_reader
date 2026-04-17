import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../preferences/domain/topic_story_matcher.dart';
import '../../../preferences/presentation/providers/topic_preferences_provider.dart';
import '../../data/datasources/firestore_datasource.dart';
import '../../data/datasources/hn_remote_datasource.dart';
import '../../data/datasources/recommended_feed_remote_datasource.dart';
import '../../data/repositories/story_repository_impl.dart';
import '../../domain/entities/story.dart';
import '../../domain/repositories/story_repository.dart';
import '../../domain/usecases/get_new_stories.dart';
import '../../domain/usecases/get_top_stories.dart';

// Feed の種類
enum FeedType { top, new_, best }

// ---- DI ----

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: ApiConstants.hnBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
});

final hnRemoteDataSourceProvider = Provider<HnRemoteDataSource>((ref) {
  return HnRemoteDataSourceImpl(dio: ref.watch(dioProvider));
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instanceFor(
    app: Firebase.app(AppConfig.instance.flavor.name),
  );
});

final firestoreDataSourceProvider = Provider<FirestoreDataSource>((ref) {
  return FirestoreDataSource(db: ref.watch(firestoreProvider));
});

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return StoryRepositoryImpl(
    remoteDataSource: ref.watch(hnRemoteDataSourceProvider),
    firestoreDataSource: ref.watch(firestoreDataSourceProvider),
  );
});

final recommendedFeedRemoteDataSourceProvider =
    Provider<RecommendedFeedRemoteDataSource>((ref) {
      return RecommendedFeedRemoteDataSource();
    });

final getTopStoriesProvider = Provider<GetTopStories>((ref) {
  return GetTopStories(ref.watch(storyRepositoryProvider));
});

final getNewStoriesProvider = Provider<GetNewStories>((ref) {
  return GetNewStories(ref.watch(storyRepositoryProvider));
});

// ---- State ----

// 現在選択中のFeedType
final feedTypeProvider = StateProvider<FeedType>((ref) => FeedType.top);

// 記事一覧
final feedProvider = AsyncNotifierProvider<FeedNotifier, List<Story>>(
  FeedNotifier.new,
);

class FeedNotifier extends AsyncNotifier<List<Story>> {
  @override
  Future<List<Story>> build() async {
    final feedType = ref.watch(feedTypeProvider);
    if (feedType == FeedType.top) {
      ref.watch(topicPreferencesProvider);
    }
    return _fetch(feedType);
  }

  Future<List<Story>> _fetch(FeedType feedType) async {
    switch (feedType) {
      case FeedType.top:
        final topicState = await ref.read(topicPreferencesProvider.future);
        final genres = topicState.selectedGenres;
        if (genres.isEmpty) {
          return ref.read(getTopStoriesProvider).call();
        }
        try {
          final fromApi = await ref
              .read(recommendedFeedRemoteDataSourceProvider)
              .fetch(genreNames: genres.map((g) => g.name).toList());
          if (fromApi.isNotEmpty) {
            return fromApi;
          }
          final top = await ref.read(getTopStoriesProvider).call();
          return sortStoriesByTopicMatch(stories: top, selectedGenres: genres);
        } catch (e, st) {
          debugPrint(
            'getRecommendedFeed failed, using HN top + client sort: $e',
          );
          debugPrint('$st');
          final top = await ref.read(getTopStoriesProvider).call();
          return sortStoriesByTopicMatch(stories: top, selectedGenres: genres);
        }
      case FeedType.new_:
        return ref.read(getNewStoriesProvider).call();
      case FeedType.best:
        return ref.read(storyRepositoryProvider).getBestStories();
    }
  }

  // 再読み込み
  Future<void> refresh() async {
    state = const AsyncLoading();
    final feedType = ref.read(feedTypeProvider);
    state = await AsyncValue.guard(() => _fetch(feedType));
  }
}
