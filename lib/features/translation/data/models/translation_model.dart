import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/translation.dart';

class TranslationModel extends Translation {
  const TranslationModel({
    required super.storyId,
    required super.titleJa,
    required super.cachedAt,
  });

  factory TranslationModel.fromJson(Map<String, dynamic> json) {
    final cachedRaw = json['cached_at'];
    final DateTime cachedAt = cachedRaw is Timestamp
        ? cachedRaw.toDate()
        : DateTime.parse(cachedRaw as String);

    return TranslationModel(
      storyId: (json['story_id'] as num).toInt(),
      titleJa: json['title_ja'] as String,
      cachedAt: cachedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'story_id': storyId,
      'title_ja': titleJa,
      'cached_at': Timestamp.fromDate(cachedAt),
    };
  }
}
