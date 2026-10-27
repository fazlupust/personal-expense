import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../models/category_model.dart';
import '../models/entry_type.dart';
import 'auth_service.dart';

class CategoryService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  AuthService get _auth => Get.find<AuthService>();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('categories');

  /// Real-time stream of all active categories
  Stream<List<CategoryModel>> streamCategories() {
    return _collection
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
    }).handleError((e) {
      debugPrint('Categories stream error: $e');
      return <CategoryModel>[];
    });
  }

  /// Add a new category with duplicate validation
  Future<String> addCategory({
    required String nameBn,
    required String nameEn,
    required EntryType type,
    String emoji = '🏷️',
  }) async {
    final uid = _auth.currentUid ?? '';

    // Duplicate check in Firestore
    String norm(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final targetEn = norm(nameEn);
    final targetBn = norm(nameBn);

    try {
      final snapshot = await _collection
          .where('type', isEqualTo: type.name)
          .where('is_active', isEqualTo: true)
          .get();

      final isDuplicate = snapshot.docs.any((doc) {
        final data = doc.data();
        final en = norm((data['name_en'] ?? '').toString());
        final bn = norm((data['name_bn'] ?? '').toString());
        final n = norm((data['name'] ?? '').toString());
        return (targetEn.isNotEmpty && (en == targetEn || bn == targetEn || n == targetEn)) ||
            (targetBn.isNotEmpty && (en == targetBn || bn == targetBn || n == targetBn));
      });

      if (isDuplicate) {
        throw Exception('That category already exists.');
      }
    } catch (e) {
      if (e.toString().contains('That category already exists.')) {
        rethrow;
      }
    }

    final docRef = _collection.doc();
    final newCat = CategoryModel(
      id: docRef.id,
      nameBn: nameBn,
      nameEn: nameEn,
      type: type,
      isActive: true,
      isDefault: false,
      createdBy: uid,
      updatedBy: uid,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      emoji: emoji,
    );
    await docRef.set(newCat.toMap());
    return docRef.id;
  }

  /// Update an existing category
  Future<void> updateCategory(CategoryModel cat) async {
    final uid = _auth.currentUid ?? '';
    await _collection.doc(cat.id).update({
      'name_bn': cat.nameBn,
      'name_en': cat.nameEn,
      'type': cat.type.name,
      'emoji': cat.emoji,
      'updated_by': uid,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Soft delete category (sets is_active to false as per specification)
  Future<void> softDeleteCategory(String categoryId) async {
    final uid = _auth.currentUid ?? '';
    await _collection.doc(categoryId).update({
      'is_active': false,
      'updated_by': uid,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Seed initial default categories if the collection has none
  Future<void> seedDefaultsIfEmpty() async {
    final uid = _auth.currentUid;
    if (uid == null) return;
    try {
      final snapshot = await _collection.limit(1).get();
      if (snapshot.docs.isNotEmpty) return;

      final batch = _db.batch();
      for (final cat in AppConstants.defaultCategories) {
        final doc = _collection.doc();
        batch.set(doc, {
          'id': doc.id,
          'name_bn': cat.nameBn,
          'name_en': cat.nameEn,
          'type': cat.type.name,
          'is_active': true,
          'is_default': true,
          'created_by': uid,
          'updated_by': uid,
          'emoji': cat.emoji,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Category seed error: $e');
    }
  }
}
