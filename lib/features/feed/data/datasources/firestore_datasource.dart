import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/story_model.dart';

/// `hn_items` から enrich 関連をバッチ取得する。
class FirestoreDataSource {
  FirestoreDataSource({required FirebaseFirestore db}) : _db = db;

  final FirebaseFirestore _db;

  static const _collection = 'hn_items';

  /// HN で得た ID 一覧に対応するドキュメントを読み、`StoryModel` で返す。
  Future<Map<int, StoryModel>> getEnrichments(List<int> ids) async {
    if (ids.isEmpty) {
      return {};
    }
    final out = <int, StoryModel>{};
    for (var i = 0; i < ids.length; i += 30) {
      final end = min(i + 30, ids.length);
      final chunk = ids.sublist(i, end);
      final strIds = chunk.map((id) => id.toString()).toList();
      final snap = await _db
          .collection(_collection)
          .where(FieldPath.documentId, whereIn: strIds)
          .get();
      for (final doc in snap.docs) {
        final model = StoryModel.fromFirestore(doc);
        if (model.id != 0) {
          out[model.id] = model;
        }
      }
    }
    return out;
  }
}
