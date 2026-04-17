import 'story_comments_enrichment.dart';

/// 詳細画面「コメント傾向」ブロックの表示用（未取得・スキップ・失敗・成功）。
sealed class CommentTrendUiResult {
  const CommentTrendUiResult();
}

/// コメントが無く、傾向ブロック自体を出さない。
final class CommentTrendUiSkipped extends CommentTrendUiResult {
  const CommentTrendUiSkipped();
}

/// Callable 失敗・パース不能。
final class CommentTrendUiFailed extends CommentTrendUiResult {
  const CommentTrendUiFailed();
}

/// 分析成功。
final class CommentTrendUiSuccess extends CommentTrendUiResult {
  final CommentTrendInsight insight;

  CommentTrendUiSuccess(this.insight);
}

/// HN コメント上位 N 件を一括で分析したセンチメント・キーワード結果（Callable 応答の表現）。
class CommentTrendInsight {
  final int positivePercent;
  final int neutralPercent;
  final int criticalPercent;
  final String positiveOpinion;
  final String neutralOpinion;
  final String criticalOpinion;
  final List<String> keywords;

  const CommentTrendInsight({
    required this.positivePercent,
    required this.neutralPercent,
    required this.criticalPercent,
    required this.positiveOpinion,
    required this.neutralOpinion,
    required this.criticalOpinion,
    required this.keywords,
  });

  factory CommentTrendInsight.fromCallableMap(Map<String, dynamic> map) {
    int pct(String camel, String snake) {
      final v = map[camel] ?? map[snake];
      if (v is int) return v.clamp(0, 100);
      if (v is num) return v.round().clamp(0, 100);
      return 0;
    }

    String line(String camel, String snake) {
      final v = map[camel] ?? map[snake];
      if (v is! String) return '';
      return v.trim();
    }

    List<String> kwList() {
      final raw = map['keywords'] ?? map['keyword_list'];
      if (raw is! List) return const [];
      return raw
          .map((e) => e?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }

    var p = pct('positivePercent', 'positive_percent');
    var n = pct('neutralPercent', 'neutral_percent');
    var c = pct('criticalPercent', 'critical_percent');
    final sum = p + n + c;
    if (sum != 100 && sum > 0) {
      p = ((p * 100) / sum).round();
      n = ((n * 100) / sum).round();
      c = 100 - p - n;
      if (c < 0) c = 0;
    }

    return CommentTrendInsight(
      positivePercent: p,
      neutralPercent: n,
      criticalPercent: c,
      positiveOpinion: line('positiveOpinion', 'positive_opinion'),
      neutralOpinion: line('neutralOpinion', 'neutral_opinion'),
      criticalOpinion: line('criticalOpinion', 'critical_opinion'),
      keywords: kwList(),
    );
  }

  /// Firestore `comments_enrichment`（negative＝ UI の「批判的」％）を UI 用に写す。
  factory CommentTrendInsight.fromStoryCommentsEnrichment(
    StoryCommentsEnrichment e,
  ) {
    var p = e.sentiment.positive;
    var n = e.sentiment.neutral;
    var c = e.sentiment.negative;
    final sum = p + n + c;
    if (sum != 100 && sum > 0) {
      p = ((p * 100) / sum).round();
      n = ((n * 100) / sum).round();
      c = 100 - p - n;
      if (c < 0) c = 0;
    }
    return CommentTrendInsight(
      positivePercent: p,
      neutralPercent: n,
      criticalPercent: c,
      positiveOpinion: '',
      neutralOpinion: e.summary,
      criticalOpinion: '',
      keywords: List<String>.from(e.keywords),
    );
  }
}
