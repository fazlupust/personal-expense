import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

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

  /// Add a new category
  Future<String> addCategory({
    required String nameBn,
    required String nameEn,
    required EntryType type,
    String emoji = '🏷️',
  }) async {
    final uid = _auth.currentUid ?? '';
    final docRef = _collection.doc();
    final newCat = CategoryModel(
      id: docRef.id,
      nameBn: nameBn,
      nameEn: nameEn,
      type: type,
      isActive: true,
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

      final defaults = [
        {'name_en': 'Food & Dining', 'name_bn': 'খাবার ও রেস্টুরেন্ট', 'type': 'expense', 'emoji': '🍔'},
        {'name_en': 'Groceries', 'name_bn': 'বাজার ও মুদি', 'type': 'expense', 'emoji': '🛒'},
        {'name_en': 'Transport', 'name_bn': 'যাতায়াত ও ভাড়া', 'type': 'expense', 'emoji': '🚗'},
        {'name_en': 'Housing & Rent', 'name_bn': 'বাড়ি ভাড়া ও মেরামত', 'type': 'expense', 'emoji': '🏠'},
        {'name_en': 'Utilities', 'name_bn': 'বিদ্যুৎ, গ্যাস ও পানি', 'type': 'expense', 'emoji': '⚡'},
        {'name_en': 'Health & Medicine', 'name_bn': 'চিকিৎসা ও ওষুধ', 'type': 'expense', 'emoji': '💊'},
        {'name_en': 'Salary', 'name_bn': 'বেতন', 'type': 'income', 'emoji': '💵'},
        {'name_en': 'Business / Freelance', 'name_bn': 'ব্যবসা ও ফ্রিল্যান্সিং', 'type': 'income', 'emoji': '💼'},
        {'name_en': 'Investment', 'name_bn': 'বিনিয়োগ ও লভ্যাংশ', 'type': 'income', 'emoji': '📈'},
        {'name_en': 'Gifts / Bonus', 'name_bn': 'উপহার ও বোনাস', 'type': 'income', 'emoji': '🎁'},
      ];

      final batch = _db.batch();
      for (final item in defaults) {
        final doc = _collection.doc();
        batch.set(doc, {
          'id': doc.id,
          'name_bn': item['name_bn'],
          'name_en': item['name_en'],
          'type': item['type'],
          'is_active': true,
          'created_by': uid,
          'updated_by': uid,
          'emoji': item['emoji'],
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
