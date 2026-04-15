import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/secrets.dart';
import '../../../../core/utils/locale_utils.dart';

abstract class ClaudeApiDataSource {
  Future<String> translateTitle(String title);
  Future<Map<int, String>> translateTitles(Map<int, String> titles);
}

class ClaudeApiDataSourceImpl implements ClaudeApiDataSource {
  final Dio _dio;

  static const String _baseUrl = 'https://api.anthropic.com';
  static const String _model = 'claude-haiku-4-5-20251001';

  ClaudeApiDataSourceImpl({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                headers: {
                  'x-api-key': Secrets.claudeApiKey,
                  'anthropic-version': '2023-06-01',
                  'content-type': 'application/json',
                },
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
              ),
            ) {
    final key = Secrets.claudeApiKey;
    final preview = key.isEmpty
        ? '空！'
        : '設定済み(${key.substring(0, key.length < 10 ? key.length : 10)}...)';
    debugPrint('=== API KEY: $preview');
  }

  @override
  Future<String> translateTitle(String title) async {
    final langCode = LocaleUtils.deviceLanguageCode;
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/messages',
      data: {
        'model': _model,
        'max_tokens': 256,
        'messages': [
          {
            'role': 'user',
            'content':
                '''Translate the following English title to $langCode language.
Return only the translated title, no explanation.

Title: $title''',
          }
        ],
      },
    );

    final data = response.data;
    if (data == null) throw StateError('Claude API: empty response');
    final content = data['content'] as List<dynamic>;
    final first = content.first as Map<String, dynamic>;
    return first['text']! as String;
  }

  @override
  Future<Map<int, String>> translateTitles(
    Map<int, String> titles,
  ) async {
    final langCode = LocaleUtils.deviceLanguageCode;
    final titlesText = titles.entries
        .map((e) => 'ID: ${e.key}: ${e.value}')
        .join('\n');

    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/messages',
      data: {
        'model': _model,
        'max_tokens': 2048,
        'messages': [
          {
            'role': 'user',
            'content':
                '''Translate the following English titles to $langCode language.
Return ONLY in the format "ID: <number>: <translated title>", one per line.
No explanation needed.

$titlesText''',
          }
        ],
      },
    );

    final data = response.data;
    if (data == null) throw StateError('Claude API: empty response');
    final content = data['content'] as List<dynamic>;
    final first = content.first as Map<String, dynamic>;
    final text = first['text']! as String;

    final result = <int, String>{};
    for (final raw in text.trim().split('\n')) {
      final parsed = _parseTranslatedTitleLine(raw);
      if (parsed != null) {
        result[parsed.$1] = parsed.$2;
      }
    }
    debugPrint('=== parsed result count: ${result.length}');
    return result;
  }
}

/// `ID: 47768133: 日本語タイトル` や `47768133: Ask HN: …` のように、先頭 ID 行と
/// タイトル内の `:` に対応する。
(int, String)? _parseTranslatedTitleLine(String raw) {
  var line = raw.trim();
  if (line.isEmpty) return null;

  line = line.replaceFirst(RegExp(r'^ID:\s*', caseSensitive: false), '');

  final sep = line.indexOf(': ');
  if (sep <= 0) return null;

  final idStr = line.substring(0, sep).trim();
  final id = int.tryParse(idStr);
  if (id == null) return null;

  final translatedTitle = line.substring(sep + 2).trim();
  if (translatedTitle.isEmpty) return null;

  return (id, translatedTitle);
}
