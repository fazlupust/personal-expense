import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/note_model.dart';
import 'auth_service.dart';
import 'device_location_service.dart';

class NoteService extends GetxService {
  static NoteService get to => Get.find<NoteService>();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  AuthService get _auth => Get.find<AuthService>();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('notes');

  /// Stream of active notes for a given user
  Stream<List<NoteModel>> streamUserNotes(String userId) {
    if (userId.isEmpty) {
      return Stream.value(<NoteModel>[]);
    }
    return _collection
        .where('user_id', isEqualTo: userId)
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NoteModel.fromFirestore(doc))
          .toList();
      // Client-side sort by date descending
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  /// Add a new note with automatic location and device info
  Future<String> addNote({
    required String title,
    required DateTime date,
    String notes = '',
    double amount = 0.0,
    String personName = '',
    double? latitude,
    double? longitude,
    String? deviceInfo,
  }) async {
    final uid = _auth.currentUid ?? _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('User not logged in');
    }

    // Fetch location safely if not provided (with 2s timeout so it never blocks)
    double? lat = latitude;
    double? lng = longitude;
    if (lat == null && lng == null) {
      try {
        final loc = await DeviceLocationService.getCurrentLocation()
            .timeout(const Duration(seconds: 2), onTimeout: () => const LocationResult());
        lat = loc.latitude;
        lng = loc.longitude;
      } catch (_) {}
    }

    // Fetch device info safely if not provided
    String? dev = deviceInfo;
    if (dev == null || dev.isEmpty) {
      try {
        dev = await DeviceLocationService.getDeviceSummary()
            .timeout(const Duration(seconds: 2), onTimeout: () => 'Unknown device');
      } catch (_) {}
    }

    final docRef = _collection.doc();
    final newNote = NoteModel(
      id: docRef.id,
      userId: uid,
      title: title,
      date: date,
      notes: notes,
      amount: amount,
      personName: personName,
      latitude: lat,
      longitude: lng,
      deviceInfo: dev,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await docRef.set(newNote.toMap());
    return docRef.id;
  }

  /// Update an existing note
  Future<void> updateNote(NoteModel note) async {
    await _collection.doc(note.id).update({
      'title': note.title,
      'date': Timestamp.fromDate(note.date),
      'notes': note.notes,
      'amount': note.amount,
      'person_name': note.personName,
      'latitude': note.latitude,
      'longitude': note.longitude,
      'device_info': note.deviceInfo,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Permanently delete a note from Firestore with soft-delete safeguard
  Future<void> deleteNote(String noteId) async {
    final docRef = _collection.doc(noteId);
    // 1. Soft-delete immediately so streamUserNotes (.where('is_active', isEqualTo: true))
    // instantly excludes it and never restores it on snapshots
    try {
      await docRef.update({
        'is_active': false,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[NoteService] soft-delete update error: $e');
    }

    // 2. Permanently remove document from Firestore
    try {
      await docRef.delete();
    } catch (e) {
      debugPrint('[NoteService] hard-delete error: $e');
    }
  }
}
