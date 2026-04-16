import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/story.dart';
import '../../domain/entities/story_enrichment.dart';

class StoryModel extends Story {
  const StoryModel({
    required super.id,
    required super.title,
    super.translatedTitle,
    super.url,
    required super.by,
    required super.score,
    required super.descendants,
    required super.time,
    required super.type,
    super.enrichStatus,
    super.enrichment,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      url: json['url'] as String?,
      by: json['by'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      descendants: json['descendants'] as int? ?? 0,
      time: json['time'] as int? ?? 0,
      type: json['type'] as String? ?? 'story',
    );
  }

  factory StoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return StoryModel(
        id: int.tryParse(doc.id) ?? 0,
        title: '',
        by: '',
        score: 0,
        descendants: 0,
        time: 0,
        type: 'story',
      );
    }
    final enrichMap = data['enrichment'] as Map<String, dynamic>?;
    final rawTime = data['time'];
    final timeSeconds = rawTime is Timestamp
        ? rawTime.seconds
        : (rawTime is int ? rawTime : 0);

    StoryEnrichment? enrichment;
    if (enrichMap != null && enrichMap['schema_version'] == 1) {
      enrichment = StoryEnrichment.fromMap(enrichMap);
    }

    return StoryModel(
      id: int.tryParse(doc.id) ?? (data['story_id'] as int? ?? 0),
      title: data['title'] as String? ?? '',
      url: data['url'] as String?,
      by: (data['by'] as String?) ?? '',
      score: (data['score'] as num?)?.toInt() ?? 0,
      descendants: (data['descendants'] as num?)?.toInt() ??
          (data['kids_count'] as num?)?.toInt() ??
          0,
      time: timeSeconds,
      type: data['type'] as String? ?? 'story',
      enrichStatus: data['enrich_status'] as String? ?? 'idle',
      enrichment: enrichment,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'translated_title': translatedTitle,
      'url': url,
      'by': by,
      'score': score,
      'descendants': descendants,
      'time': time,
      'type': type,
    };
  }

  StoryModel copyWith({
    String? translatedTitle,
    String? enrichStatus,
    StoryEnrichment? enrichment,
  }) {
    return StoryModel(
      id: id,
      title: title,
      translatedTitle: translatedTitle ?? this.translatedTitle,
      url: url,
      by: by,
      score: score,
      descendants: descendants,
      time: time,
      type: type,
      enrichStatus: enrichStatus ?? this.enrichStatus,
      enrichment: enrichment ?? this.enrichment,
    );
  }
}
