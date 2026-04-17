import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/story.dart';
import '../../domain/repositories/story_repository.dart';
import '../datasources/firestore_datasource.dart';
import '../datasources/hn_remote_datasource.dart';
import '../models/story_model.dart';

class StoryRepositoryImpl implements StoryRepository {
  StoryRepositoryImpl({
    required HnRemoteDataSource remoteDataSource,
    required FirestoreDataSource firestoreDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _firestoreDataSource = firestoreDataSource;

  final HnRemoteDataSource _remoteDataSource;
  final FirestoreDataSource _firestoreDataSource;

  @override
  Future<List<Story>> getTopStories(
      {int limit = ApiConstants.storiesPerPage}) async {
    final ids = await _remoteDataSource.getTopStoryIds();
    return _fetchStoriesWithEnrichment(ids.take(limit).toList());
  }

  @override
  Future<List<Story>> getNewStories(
      {int limit = ApiConstants.storiesPerPage}) async {
    final ids = await _remoteDataSource.getNewStoryIds();
    return _fetchStoriesWithEnrichment(ids.take(limit).toList());
  }

  @override
  Future<List<Story>> getBestStories(
      {int limit = ApiConstants.storiesPerPage}) async {
    final ids = await _remoteDataSource.getBestStoryIds();
    return _fetchStoriesWithEnrichment(ids.take(limit).toList());
  }

  @override
  Future<Story?> getStory(int id) async {
    final story = await _remoteDataSource.getStory(id);
    if (story == null) {
      return null;
    }
    final enrichMap = await _firestoreDataSource.getEnrichments([id]);
    final enriched = enrichMap[id];
    if (enriched == null) {
      return story;
    }
    return story.copyWith(
      enrichStatus: enriched.enrichStatus,
      enrichment: enriched.enrichment,
      commentsEnrichment: enriched.commentsEnrichment,
    );
  }

  Future<List<Story>> _fetchStoriesWithEnrichment(List<int> ids) async {
    final results = await Future.wait([
      Future.wait(ids.map(_remoteDataSource.getStory)),
      _firestoreDataSource.getEnrichments(ids),
    ]);

    final hnList = results[0] as List<StoryModel?>;
    final enrichMap = results[1] as Map<int, StoryModel>;

    final stories = hnList
        .whereType<StoryModel>()
        .where((s) => s.type == 'story' && s.title.isNotEmpty)
        .toList();

    return stories.map((story) {
      final enriched = enrichMap[story.id];
      if (enriched == null) {
        return story;
      }
      return story.copyWith(
        enrichStatus: enriched.enrichStatus,
        enrichment: enriched.enrichment,
        commentsEnrichment: enriched.commentsEnrichment,
      );
    }).toList();
  }
}
