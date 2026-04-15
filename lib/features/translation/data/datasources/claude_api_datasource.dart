import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/secrets.dart';

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
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/messages',
      data: {
        'model': _model,
        'max_tokens': 256,
        'messages': [
          {
            'role': 'user',
            'content':
                '''以下の英語タイトルを自然な日本語に翻訳してください。
翻訳結果のみ返してください。説明は不要です。

タイトル: $title''',
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
    final titlesText = titles.entries
        .map((e) => '${e.key}: ${e.value}')
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
                '''以下の英語タイトル一覧を日本語に翻訳してください。
各行は必ず次の形式にしてください（先頭に ID: を付けること）:
ID: <数値ID>: <日本語タイトル>
余計な説明や見出しは付けないでください。

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

  final titleJa = line.substring(sep + 2).trim();
  if (titleJa.isEmpty) return null;

  return (id, titleJa);
}
