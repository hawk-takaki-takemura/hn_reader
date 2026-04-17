import '../../feed/domain/entities/story.dart';
import '../presentation/providers/topic_preferences_provider.dart';

List<Story> sortStoriesByTopicMatch({
  required List<Story> stories,
  required Set<TopicGenre> selectedGenres,
}) {
  if (selectedGenres.isEmpty) return stories;

  final scored =
      stories
          .map(
            (story) => (
              story: story,
              score: _scoreStoryForGenres(story, selectedGenres),
            ),
          )
          .toList();

  scored.sort((a, b) => b.score.compareTo(a.score));
  return scored.map((row) => row.story).toList();
}

int _scoreStoryForGenres(Story story, Set<TopicGenre> selectedGenres) {
  final text = _searchableText(story).toLowerCase();
  var score = 0;

  for (final genre in selectedGenres) {
    final keywords = topicGenreKeywords[genre] ?? const <String>[];
    for (final keyword in keywords) {
      final k = keyword.toLowerCase();
      if (k.isEmpty) continue;
      if (text.contains(k)) {
        score += 3;
      }
    }
  }

  // もともとの評価も少し加味して過度な偏りを抑える
  score += (story.score / 100).floor();
  return score;
}

/// HN 原文・表示タイトル・URL・Firestore enrich（タグ・要約）をまとめた検索用テキスト。
String _searchableText(Story story) {
  final e = story.enrichment;
  final parts = <String>[
    story.title,
    story.translatedTitle ?? '',
    story.displayTitle,
    story.url ?? '',
    if (e != null) ...[
      e.titleJa ?? '',
      e.summaryShort ?? '',
      ...e.summaryPoints,
      ...e.tags,
    ],
  ];
  return parts.join(' ');
}
