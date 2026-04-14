import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/story_model.dart';

abstract class HnRemoteDataSource {
  Future<List<int>> getTopStoryIds();
  Future<List<int>> getNewStoryIds();
  Future<List<int>> getBestStoryIds();
  Future<StoryModel?> getStory(int id);
}

class HnRemoteDataSourceImpl implements HnRemoteDataSource {
  final Dio _dio;

  HnRemoteDataSourceImpl({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.hnBaseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  @override
  Future<List<int>> getTopStoryIds() async {
    final response = await _dio.get(ApiConstants.topStoriesEndpoint);
    return List<int>.from(response.data as List<dynamic>);
  }

  @override
  Future<List<int>> getNewStoryIds() async {
    final response = await _dio.get(ApiConstants.newStoriesEndpoint);
    return List<int>.from(response.data as List<dynamic>);
  }

  @override
  Future<List<int>> getBestStoryIds() async {
    final response = await _dio.get(ApiConstants.bestStoriesEndpoint);
    return List<int>.from(response.data as List<dynamic>);
  }

  @override
  Future<StoryModel?> getStory(int id) async {
    try {
      final response =
          await _dio.get('${ApiConstants.itemEndpoint}/$id.json');
      if (response.data == null) return null;
      return StoryModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } catch (_) {
      return null;
    }
  }
}
