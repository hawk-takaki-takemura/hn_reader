import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../data/datasources/hn_remote_datasource.dart';
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

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return StoryRepositoryImpl(
    remoteDataSource: ref.watch(hnRemoteDataSourceProvider),
  );
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
    return _fetch();
  }

  Future<List<Story>> _fetch() async {
    final feedType = ref.watch(feedTypeProvider);
    switch (feedType) {
      case FeedType.top:
        return ref.read(getTopStoriesProvider).call();
      case FeedType.new_:
        return ref.read(getNewStoriesProvider).call();
      case FeedType.best:
        return ref.read(storyRepositoryProvider).getBestStories();
    }
  }

  // 再読み込み
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}
