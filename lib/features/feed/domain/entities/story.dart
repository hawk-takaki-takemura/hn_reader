class Story {
  final int id;
  final String title;
  /// 端末言語向けの翻訳タイトル（未取得時は null）
  final String? translatedTitle;
  final String? url;
  final String by; // 投稿者
  final int score; // スコア
  final int descendants; // コメント数
  final int time; // 投稿時刻（Unix time）
  final String type; // story, ask, job etc.

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
  });

  // 投稿時刻をDateTimeに変換
  DateTime get postedAt =>
      DateTime.fromMillisecondsSinceEpoch(time * 1000);

  // 表示用タイトル（日本語があれば日本語を優先）
  String get displayTitle => translatedTitle ?? title;

  // ドメイン名を取得（例: github.com）
  String? get domain {
    if (url == null) return null;
    try {
      return Uri.parse(url!).host.replaceAll('www.', '');
    } catch (_) {
      return null;
    }
  }
}
