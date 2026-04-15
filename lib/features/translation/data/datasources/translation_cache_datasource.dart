import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/locale_utils.dart';
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
  final String _languageCode;

  static const String _baseCollection = 'translations';
  static const String _storiesSubcollection = 'stories';

  TranslationCacheDataSourceImpl({
    FirebaseFirestore? firestore,
    String? languageCode,
  })  : _firestore = firestore ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(AppConfig.instance.flavor.name),
            ),
        _languageCode = languageCode ?? LocaleUtils.deviceLanguageCode;

  /// `translations/{languageCode}/stories/{storyId}`
  CollectionReference<Map<String, dynamic>> get _storiesCollection =>
      _firestore
          .collection(_baseCollection)
          .doc(_languageCode)
          .collection(_storiesSubcollection);

  @override
  Future<TranslationModel?> getTranslation(int storyId) async {
    final doc = await _storiesCollection.doc(storyId.toString()).get();

    if (!doc.exists || doc.data() == null) return null;
    return TranslationModel.fromJson(
      Map<String, dynamic>.from(doc.data()!),
    );
  }

  @override
  Future<void> saveTranslation(TranslationModel translation) async {
    await _storiesCollection
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
      final snapshot = await _storiesCollection
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
