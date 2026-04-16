/// Firestore `hn_items.enrichment`（V1）のクライアント側表現。
class StoryEnrichment {
  final String? titleJa;
  final String? summaryShort;
  final List<String> summaryPoints;
  final List<String> tags;
  final double? confidenceScore;
  final double? hotTopicScore;

  const StoryEnrichment({
    this.titleJa,
    this.summaryShort,
    this.summaryPoints = const [],
    this.tags = const [],
    this.confidenceScore,
    this.hotTopicScore,
  });

  factory StoryEnrichment.fromMap(Map<String, dynamic> map) {
    return StoryEnrichment(
      titleJa: map['title_ja'] as String?,
      summaryShort: map['summary_short'] as String?,
      summaryPoints: List<String>.from(map['summary_points'] as List? ?? const []),
      tags: List<String>.from(map['tags'] as List? ?? const []),
      confidenceScore: (map['confidence_score'] as num?)?.toDouble(),
      hotTopicScore: (map['hot_topic_score'] as num?)?.toDouble(),
    );
  }
}
