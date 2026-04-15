class Translation {
  final int storyId;
  final String translatedTitle;
  final DateTime cachedAt;

  const Translation({
    required this.storyId,
    required this.translatedTitle,
    required this.cachedAt,
  });

  bool get isExpired {
    return DateTime.now().difference(cachedAt).inHours > 24;
  }
}
