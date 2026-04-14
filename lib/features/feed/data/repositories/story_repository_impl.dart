import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/story.dart';
import '../../domain/repositories/story_repository.dart';
import '../datasources/hn_remote_datasource.dart';

class StoryRepositoryImpl implements StoryRepository {
  final HnRemoteDataSource _remoteDataSource;

  StoryRepositoryImpl({required HnRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<Story>> getTopStories(
      {int limit = ApiConstants.storiesPerPage}) async {
    final ids = await _remoteDataSource.getTopStoryIds();
    return _fetchStories(ids.take(limit).toList());
  }

  @override
  Future<List<Story>> getNewStories(
      {int limit = ApiConstants.storiesPerPage}) async {
    final ids = await _remoteDataSource.getNewStoryIds();
    return _fetchStories(ids.take(limit).toList());
  }

  @override
  Future<List<Story>> getBestStories(
      {int limit = ApiConstants.storiesPerPage}) async {
    final ids = await _remoteDataSource.getBestStoryIds();
    return _fetchStories(ids.take(limit).toList());
  }

  @override
  Future<Story?> getStory(int id) async {
    return _remoteDataSource.getStory(id);
  }

  // 複数のstoryを並列取得
  Future<List<Story>> _fetchStories(List<int> ids) async {
    final futures = ids.map((id) => _remoteDataSource.getStory(id));
    final results = await Future.wait(futures);
    return results
        .whereType<Story>()
        .where((s) => s.type == 'story' && s.title.isNotEmpty)
        .toList();
  }
}
