import 'translation_data_source.dart';

/// Callable を使わない経路（Remote Config `translation_backend=local` など）。
class TranslationNoopDataSource implements TranslationDataSource {
  const TranslationNoopDataSource();

  @override
  Future<String> translateTitle(String title) async => title;

  @override
  Future<Map<int, String>> translateTitles(Map<int, String> titles) async =>
      const {};
}
