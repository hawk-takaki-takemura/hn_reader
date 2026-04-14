import '../../domain/entities/story.dart';

class StoryModel extends Story {
  const StoryModel({
    required super.id,
    required super.title,
    super.titleJa,
    super.url,
    required super.by,
    required super.score,
    required super.descendants,
    required super.time,
    required super.type,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'title_ja': titleJa,
      'url': url,
      'by': by,
      'score': score,
      'descendants': descendants,
      'time': time,
      'type': type,
    };
  }

  StoryModel copyWith({String? titleJa}) {
    return StoryModel(
      id: id,
      title: title,
      titleJa: titleJa ?? this.titleJa,
      url: url,
      by: by,
      score: score,
      descendants: descendants,
      time: time,
      type: type,
    );
  }
}
