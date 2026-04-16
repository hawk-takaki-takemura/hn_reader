import 'story_enrichment.dart';

class Story {
  final int id;
  final String title;
  /// 端末言語向けの翻訳タイトル（未取得時は null）
  final String? translatedTitle;
  final String? url;
  final String by;
  final int score;
  final int descendants;
  final int time;
  final String type;

  /// Firestore `hn_items.enrich_status`
  final String enrichStatus;

  final StoryEnrichment? enrichment;

  const Story({
    required this.id,
    required this.title,
    this.translatedTitle,
    this.url,
    required this.by,
    required this.score,
    required this.descendants,
    required this.time,
    required this.type,
    this.enrichStatus = 'idle',
    this.enrichment,
  });

  DateTime get postedAt =>
      DateTime.fromMillisecondsSinceEpoch(time * 1000);

  /// 表示用タイトルの優先ルール（B-2 確定 2026-04-16）
  ///
  /// 優先順位:
  ///   1. `enrichment.title_ja`（`enrich_status == 'completed'` かつ非空）
  ///      本文コンテキスト込みのパイプライン出力を正とする。
  ///   2. `translatedTitle`（Callable `translateStories` の結果）
  ///      enrich 未完了・失敗時の補助。鮮度競合では enrichment を優先。
  ///   3. `title`（HN 原文）
  ///
  /// 参照: yomi-backend の `functions/RUNBOOK.md` 内「B-2 title_ja 優先ルール」節。
  String get displayTitle {
    if (enrichStatus == 'completed' && enrichment?.titleJa != null) {
      final ja = enrichment!.titleJa!.trim();
      if (ja.isNotEmpty) {
        return ja;
      }
    }
    return translatedTitle ?? title;
  }

  bool get hasEnrichment =>
      enrichStatus == 'completed' && enrichment != null;

  String? get domain {
    if (url == null) return null;
    try {
      return Uri.parse(url!).host.replaceAll('www.', '');
    } catch (_) {
      return null;
    }
  }
}
