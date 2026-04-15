import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/translation.dart';

class TranslationModel extends Translation {
  const TranslationModel({
    required super.storyId,
    required super.translatedTitle,
    required super.cachedAt,
  });

  factory TranslationModel.fromJson(Map<String, dynamic> json) {
    final cachedRaw = json['cached_at'];
    final DateTime cachedAt = cachedRaw is Timestamp
        ? cachedRaw.toDate()
        : DateTime.parse(cachedRaw as String);

    final titleRaw = json['translated_title'] ?? json['title_ja'];

    return TranslationModel(
      storyId: (json['story_id'] as num).toInt(),
      translatedTitle: titleRaw as String,
      cachedAt: cachedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'story_id': storyId,
      'translated_title': translatedTitle,
      'cached_at': Timestamp.fromDate(cachedAt),
    };
  }
}
