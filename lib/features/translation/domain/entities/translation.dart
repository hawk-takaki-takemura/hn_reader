class Translation {
  final int storyId;
  final String titleJa;
  final DateTime cachedAt;

  const Translation({
    required this.storyId,
    required this.titleJa,
    required this.cachedAt,
  });

  bool get isExpired {
    return DateTime.now().difference(cachedAt).inHours > 24;
  }
}
