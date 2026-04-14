import '../entities/story.dart';
import '../repositories/story_repository.dart';

class GetTopStories {
  final StoryRepository _repository;

  GetTopStories(this._repository);

  Future<List<Story>> call({int limit = 30}) {
    return _repository.getTopStories(limit: limit);
  }
}
