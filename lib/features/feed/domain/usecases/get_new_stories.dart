import '../entities/story.dart';
import '../repositories/story_repository.dart';

class GetNewStories {
  final StoryRepository _repository;

  GetNewStories(this._repository);

  Future<List<Story>> call({int limit = 30}) {
    return _repository.getNewStories(limit: limit);
  }
}
