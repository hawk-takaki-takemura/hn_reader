import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/config/app_config.dart';
import '../models/translation_model.dart';

abstract class TranslationCacheDataSource {
  Future<TranslationModel?> getTranslation(int storyId);
  Future<void> saveTranslation(TranslationModel translation);
  Future<Map<int, TranslationModel>> getTranslations(
    List<int> storyIds,
  );
}

class TranslationCacheDataSourceImpl implements TranslationCacheDataSource {
  final FirebaseFirestore _firestore;

  static const String _collection = 'translations';

  TranslationCacheDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(AppConfig.instance.flavor.name),
            );

  @override
  Future<TranslationModel?> getTranslation(int storyId) async {
    final doc = await _firestore
        .collection(_collection)
        .doc(storyId.toString())
        .get();

    if (!doc.exists || doc.data() == null) return null;
    return TranslationModel.fromJson(
      Map<String, dynamic>.from(doc.data()!),
    );
  }

  @override
  Future<void> saveTranslation(TranslationModel translation) async {
    await _firestore
        .collection(_collection)
        .doc(translation.storyId.toString())
        .set(translation.toJson());
  }

  @override
  Future<Map<int, TranslationModel>> getTranslations(
    List<int> storyIds,
  ) async {
    final result = <int, TranslationModel>{};
    final chunks = <List<int>>[];

    for (var i = 0; i < storyIds.length; i += 10) {
      chunks.add(
        storyIds.sublist(
          i,
          i + 10 > storyIds.length ? storyIds.length : i + 10,
        ),
      );
    }

    for (final chunk in chunks) {
      final snapshot = await _firestore
          .collection(_collection)
          .where(
            FieldPath.documentId,
            whereIn: chunk.map((id) => id.toString()).toList(),
          )
          .get();

      for (final doc in snapshot.docs) {
        final model = TranslationModel.fromJson(
          Map<String, dynamic>.from(doc.data()),
        );
        result[model.storyId] = model;
      }
    }
    return result;
  }
}
