abstract class TranslationDataSource {
  Future<String> translateTitle(String title);
  Future<Map<int, String>> translateTitles(Map<int, String> titles);
}
