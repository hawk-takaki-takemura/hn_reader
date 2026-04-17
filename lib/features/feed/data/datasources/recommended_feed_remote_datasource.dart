import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/config/app_config.dart';
import '../models/story_model.dart';
import '../../domain/entities/story.dart';

/// Cloud Functions Callable `getRecommendedFeed`（enrich 済み `hn_items` をタグで絞り込み）。
class RecommendedFeedRemoteDataSource {
  RecommendedFeedRemoteDataSource({FirebaseFunctions? functions})
    : _functions =
          functions ??
          FirebaseFunctions.instanceFor(
            app: Firebase.app(AppConfig.instance.flavor.name),
            region: 'asia-northeast1',
          );

  final FirebaseFunctions _functions;

  static const int _defaultLimit = 30;

  Future<List<Story>> fetch({
    required List<String> genreNames,
    int limit = _defaultLimit,
  }) async {
    final callable = _functions.httpsCallable(
      'getRecommendedFeed',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );

    final response = await callable.call<Map<String, dynamic>>({
      'genres': genreNames,
      'limit': limit,
    });

    final data = response.data;
    final raw = data['stories'];
    if (raw is! List) {
      throw StateError('getRecommendedFeed: invalid response (stories)');
    }

    final out = <Story>[];
    for (final item in raw) {
      if (item is! Map) continue;
      out.add(
        StoryModel.fromRecommendedFeedMap(Map<String, dynamic>.from(item)),
      );
    }
    return out;
  }
}
