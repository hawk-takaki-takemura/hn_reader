class ApiConstants {
  ApiConstants._();

  // HN API
  static const String hnBaseUrl =
      'https://hacker-news.firebaseio.com/v0';
  static const String topStoriesEndpoint = '/topstories.json';
  static const String newStoriesEndpoint = '/newstories.json';
  static const String bestStoriesEndpoint = '/beststories.json';
  static const String itemEndpoint = '/item';

  // 一度に取得する記事数
  static const int storiesPerPage = 30;
}
