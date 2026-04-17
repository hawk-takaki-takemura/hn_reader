import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/entities/comment_trend_insight.dart';

/// Cloud Functions Callable `analyzeHnCommentTrends` を呼び出す。
///
/// サーバー側では [storyId] から上位コメント（既定 20 件）を取得し、
/// 1 回の LLM 呼び出しで割合・主な意見・キーワードを JSON で返す想定。
/// 任意で [commentSnippets] を渡すと、HN の再取得を省略できる実装にも対応しやすい。
class CommentTrendRemoteDataSource {
  CommentTrendRemoteDataSource({FirebaseFunctions? functions})
    : _functions =
          functions ??
          FirebaseFunctions.instanceFor(
            app: Firebase.app(AppConfig.instance.flavor.name),
            region: 'asia-northeast1',
          );

  final FirebaseFunctions _functions;

  static const String _callableName = 'analyzeHnCommentTrends';

  /// サーバー実装向け: 上位 [limit] 件のコメント本文を 1 回の LLM に渡し、JSON で返す。
  /// プロンプト例（要旨）:
  /// - 入力: 番号付きコメント一覧（日本語訳または原文）
  /// - 出力: 肯定的・中性的・批判的の割合（合計100）、各カテゴリの主な意見を日本語1文、
  ///   頻出キーワード5〜12個（名詞句）
  /// - 禁止: 個人攻撃の拡大、コメントにない主張の捏造
  Future<CommentTrendInsight?> analyze({
    required int storyId,
    int limit = 20,
    List<Map<String, dynamic>>? commentSnippets,
  }) async {
    final callable = _functions.httpsCallable(
      _callableName,
      options: HttpsCallableOptions(timeout: const Duration(seconds: 55)),
    );

    final payload = <String, dynamic>{
      'storyId': storyId,
      'limit': limit,
      if (commentSnippets != null && commentSnippets.isNotEmpty)
        'comments': commentSnippets,
    };

    final response = await callable.call<Map<String, dynamic>>(payload);
    final data = response.data;
    final trend = data['trend'] ?? data;
    if (trend is! Map) return null;
    return CommentTrendInsight.fromCallableMap(Map<String, dynamic>.from(trend));
  }
}
