import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/entry_type.dart';
import '../models/transaction_model.dart';
import 'auth_service.dart';
import 'device_location_service.dart';

class TransactionService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  AuthService get _auth => Get.find<AuthService>();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('transactions');

  /// Stream of active (non-deleted) transactions for the current logged-in user.
  /// Queries strictly by user_id to match security rules and avoid composite index requirements.
  Stream<List<TransactionModel>> streamUserTransactions(String userId) {
    return _collection
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .where((tx) => !tx.isDeleted)
          .toList();
      // Sort client-side by date descending
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  /// One-shot fetch of transactions for the current user (used on app open & pull-to-refresh)
  Future<List<TransactionModel>> fetchUserTransactions(String userId) async {
    try {
      final snapshot = await _collection
          .where('user_id', isEqualTo: userId)
          .get()
          .timeout(const Duration(seconds: 5));
      final list = snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .where((tx) => !tx.isDeleted)
          .toList();

      // Fallback 1: Check subcollection users/{userId}/transactions if root query returned 0
      if (list.isEmpty) {
        try {
          final subSnap = await _db
              .collection('users')
              .doc(userId)
              .collection('transactions')
              .get()
              .timeout(const Duration(seconds: 4));
          if (subSnap.docs.isNotEmpty) {
            final subList = subSnap.docs
                .map((doc) => TransactionModel.fromFirestore(doc))
                .where((tx) => !tx.isDeleted)
                .toList();
            list.addAll(subList);
          }
        } catch (_) {}
      }

      // Fallback 2: If developer and still empty, check top-level transactions
      if (list.isEmpty && _auth.isDeveloper) {
        try {
          final allSnap = await _collection
              .limit(100)
              .get()
              .timeout(const Duration(seconds: 4));
          if (allSnap.docs.isNotEmpty) {
            final allList = allSnap.docs
                .map((doc) => TransactionModel.fromFirestore(doc))
                .where((tx) => !tx.isDeleted)
                .toList();
            list.addAll(allList);
          }
        } catch (_) {}
      }

      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (e) {
      debugPrint('[TransactionService] fetchUserTransactions error: $e');
      return [];
    }
  }

  /// Add a new transaction with category snapshot, safe location and device info
  Future<String> addTransaction({
    required String categoryId,
    required String categoryNameBn,
    required String categoryNameEn,
    required EntryType type,
    required double amount,
    String? noteBn,
    String? noteEn,
    required DateTime date,
    String account = 'Cash',
    double? latitude,
    double? longitude,
    String? deviceInfo,
  }) async {
    final uid = _auth.currentUid;
    if (uid == null) throw Exception('User not logged in');

    // If location is not explicitly passed, attempt to fetch safely (null if off or denied)
    // Never pop blocking permission dialogs during transaction creation
    double? lat = latitude;
    double? lng = longitude;
    if (lat == null && lng == null) {
      final loc = await DeviceLocationService.getCurrentLocation(requestIfNotGranted: false);
      lat = loc.latitude;
      lng = loc.longitude;
    }

    // If device info is not passed, fetch device summary
    String? dev = deviceInfo;
    if (dev == null || dev.isEmpty) {
      dev = await DeviceLocationService.getDeviceSummary();
    }

    final docRef = _collection.doc();
    final newTx = TransactionModel(
      id: docRef.id,
      userId: uid,
      categoryId: categoryId,
      categoryNameBn: categoryNameBn,
      categoryNameEn: categoryNameEn,
      type: type,
      amount: amount,
      noteBn: noteBn,
      noteEn: noteEn,
      date: date,
      isDeleted: false,
      account: account,
      latitude: lat,
      longitude: lng,
      deviceInfo: dev,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await docRef.set(newTx.toMap()).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Transaction save timed out. Please check your network connection.'),
    );
    try {
      await _db.collection('users').doc(uid).set({
        'transaction_count': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (_) {}
    return docRef.id;
  }

  /// Update an existing transaction
  Future<void> updateTransaction(TransactionModel tx) async {
    final updateData = <String, dynamic>{
      'category_id': tx.categoryId,
      'category_name_bn': tx.categoryNameBn,
      'category_name_en': tx.categoryNameEn,
      'type': tx.type.name,
      'amount': tx.amount,
      'note_bn': tx.noteBn,
      'note_en': tx.noteEn,
      'transaction_date': Timestamp.fromDate(tx.date),
      'account': tx.account,
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (tx.latitude != null) updateData['latitude'] = tx.latitude;
    if (tx.longitude != null) updateData['longitude'] = tx.longitude;
    if (tx.deviceInfo != null) updateData['device_info'] = tx.deviceInfo;

    await _collection.doc(tx.id).update(updateData);
  }

  /// Permanently delete transaction from Firestore with reliable soft-delete fallback
  Future<void> deleteTransaction(String id) async {
    try {
      final docRef = _collection.doc(id);
      final docSnap = await docRef.get();
      final uid = docSnap.data()?['user_id'] as String?;

      // 1. Soft-delete immediately so streamUserTransactions (.where('is_deleted', isEqualTo: false))
      // instantly removes it and never resurrects it on snapshot updates
      try {
        await docRef.update({
          'is_deleted': true,
          'updated_at': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('[TransactionService] soft-delete update error: $e');
      }

      // 2. Decrement transaction count
      if (uid != null && uid.isNotEmpty) {
        try {
          await _db.collection('users').doc(uid).set({
            'transaction_count': FieldValue.increment(-1),
          }, SetOptions(merge: true));
        } catch (_) {}
      }

      // 3. Permanently remove document from Firestore
      try {
        await docRef.delete();
      } catch (e) {
        debugPrint('[TransactionService] hard-delete error: $e');
      }
    } catch (e) {
      debugPrint('[TransactionService] deleteTransaction error: $e');
      try {
        await _collection.doc(id).delete();
      } catch (_) {}
    }
  }

  /// Alias for backward compatibility
  Future<void> softDeleteTransaction(String id) => deleteTransaction(id);

  /// Stream mapping of {userId: transactionCount} for all active transactions across users
  Stream<Map<String, int>> streamAllUserTransactionCounts() {
    return _collection
        .where('is_deleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final map = <String, int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final uid = data['user_id'] as String?;
        if (uid != null && uid.isNotEmpty) {
          map[uid] = (map[uid] ?? 0) + 1;
        }
      }
      return map;
    }).handleError((_) => <String, int>{});
  }
}
