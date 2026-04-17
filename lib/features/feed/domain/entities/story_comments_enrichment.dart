import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore `hn_items.comments_enrichment`（V1）のクライアント表現。
///
/// バックエンド: [commentEnrichmentTypes.ts](yomi-backend) の
/// `CommentsEnrichmentV1` および `processCommentsEnrichment` の `merge` 保存形。
class StoryCommentsEnrichment {
  final int schemaVersion;
  final StoryCommentsSentiment sentiment;
  final String summary;
  final List<String> keywords;
  final List<StoryTopCommentEnrichment> topComments;
  final DateTime? analyzedAt;

  const StoryCommentsEnrichment({
    required this.schemaVersion,
    required this.sentiment,
    required this.summary,
    required this.keywords,
    required this.topComments,
    this.analyzedAt,
  });

  /// 詳細画面でコメント一覧・傾向の「キャッシュヒット」表示に使えるか。
  bool get isReadyForDetailUi =>
      schemaVersion == 1 && topComments.isNotEmpty;

  /// [raw] は `comments_enrichment` マップ全体。
  static StoryCommentsEnrichment? tryFromMap(Map<String, dynamic> raw) {
    final sv = raw['schema_version'];
    if (sv != 1) return null;

    final sentRaw = raw['sentiment'];
    if (sentRaw is! Map) return null;
    final sm = Map<String, dynamic>.from(sentRaw);
    final sentiment = StoryCommentsSentiment(
      positive: _pct(sm['positive']),
      neutral: _pct(sm['neutral']),
      negative: _pct(sm['negative']),
    );

    final summary = (raw['summary'] as String?)?.trim() ?? '';
    final keywords = _parseKeywords(raw['keywords']);

    final topComments = _parseTopComments(raw['top_comments']);
    if (topComments.isEmpty) return null;

    final analyzedAt = _parseAnalyzedAt(raw['analyzed_at']);

    return StoryCommentsEnrichment(
      schemaVersion: 1,
      sentiment: sentiment,
      summary: summary,
      keywords: keywords,
      topComments: topComments,
      analyzedAt: analyzedAt,
    );
  }

  static int _pct(Object? v) {
    if (v is int) return v.clamp(0, 100);
    if (v is num) return v.round().clamp(0, 100);
    if (v is String) {
      final x = int.tryParse(v.trim());
      if (x == null) return 0;
      return x.clamp(0, 100);
    }
    return 0;
  }

  static List<String> _parseKeywords(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e?.toString().trim() ?? '')
        .where((s) => s.isNotEmpty)
        .take(16)
        .toList();
  }

  static List<StoryTopCommentEnrichment> _parseTopComments(Object? raw) {
    if (raw is! List) return const [];
    final out = <StoryTopCommentEnrichment>[];
    for (final row in raw) {
      if (out.length >= 20) break;
      if (row is! Map) continue;
      final m = Map<String, dynamic>.from(row);
      final idRaw = m['id'] ?? m['comment_id'];
      int? id;
      if (idRaw is int && idRaw > 0) {
        id = idRaw;
      } else if (idRaw is num) {
        final i = idRaw.toInt();
        id = i > 0 ? i : null;
      } else if (idRaw is String) {
        id = int.tryParse(idRaw.trim());
        if (id != null && id <= 0) id = null;
      }
      if (id == null) continue;
      final textJa = (m['text_ja'] as String?)?.trim() ?? '';
      if (textJa.isEmpty) continue;
      final sent = (m['sentiment'] as String?)?.trim() ?? '';
      if (sent != 'positive' && sent != 'neutral' && sent != 'negative') {
        continue;
      }
      out.add(
        StoryTopCommentEnrichment(
          id: id,
          textJa: textJa,
          sentiment: sent,
        ),
      );
    }
    return out;
  }

  static DateTime? _parseAnalyzedAt(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    return null;
  }
}

class StoryCommentsSentiment {
  final int positive;
  final int neutral;
  final int negative;

  const StoryCommentsSentiment({
    required this.positive,
    required this.neutral,
    required this.negative,
  });
}

class StoryTopCommentEnrichment {
  final int id;
  final String textJa;
  /// `positive` | `neutral` | `negative`（Firestore 保存値）
  final String sentiment;

  const StoryTopCommentEnrichment({
    required this.id,
    required this.textJa,
    required this.sentiment,
  });
}
