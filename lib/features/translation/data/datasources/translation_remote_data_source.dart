import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/locale_utils.dart';
import 'translation_data_source.dart';

/// Cloud Functions Callable `translateStories` を呼び出す。
class TranslationRemoteDataSource implements TranslationDataSource {
  TranslationRemoteDataSource({FirebaseFunctions? functions})
    : _functions =
          functions ??
          FirebaseFunctions.instanceFor(
            app: Firebase.app(AppConfig.instance.flavor.name),
            region: 'asia-northeast1',
          );

  final FirebaseFunctions _functions;

  static const int _maxStoriesPerRequest = 20;
  static const int _maxTitleLength = 200;

  @override
  Future<String> translateTitle(String title) async {
    final translated = await translateTitles({0: title});
    return translated[0] ?? title;
  }

  @override
  Future<Map<int, String>> translateTitles(Map<int, String> titles) async {
    if (titles.isEmpty) return const {};

    final clipped = <int, String>{
      for (final e in titles.entries) e.key: _clipTitle(e.value),
    };

    final merged = <int, String>{};
    final entries = clipped.entries.toList();
    for (var i = 0; i < entries.length; i += _maxStoriesPerRequest) {
      final end = (i + _maxStoriesPerRequest > entries.length)
          ? entries.length
          : i + _maxStoriesPerRequest;
      final chunk = Map<int, String>.fromEntries(entries.sublist(i, end));
      merged.addAll(await _translateChunk(chunk));
    }

    debugPrint('=== remote translated count: ${merged.length}');
    return merged;
  }

  Future<Map<int, String>> _translateChunk(Map<int, String> titles) async {
    final callable = _functions.httpsCallable(
      'translateStories',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );

    final payload = <String, dynamic>{
      'stories': {
        for (final e in titles.entries) e.key.toString(): e.value,
      },
      'lang': LocaleUtils.deviceLanguageCode,
    };

    final response = await callable.call<Map<String, dynamic>>(payload);
    final data = response.data;
    final rawTranslations = data['translations'];
    if (rawTranslations is! Map) {
      throw StateError('translateStories: invalid response format');
    }

    final parsed = <int, String>{};
    rawTranslations.forEach((dynamic key, dynamic value) {
      final id = int.tryParse(key.toString());
      if (id == null) return;
      if (value is! String || value.trim().isEmpty) return;
      parsed[id] = value;
    });
    return parsed;
  }

  static String _clipTitle(String title) {
    if (title.length <= _maxTitleLength) return title;
    return title.substring(0, _maxTitleLength);
  }
}
