import '../entities/story.dart';

abstract class StoryRepository {
  Future<List<Story>> getTopStories({int limit = 30});
  Future<List<Story>> getNewStories({int limit = 30});
  Future<List<Story>> getBestStories({int limit = 30});
  Future<Story?> getStory(int id);
}
