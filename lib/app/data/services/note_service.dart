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
    }).handleError((e) {
      debugPrint('Notes stream error: $e');
      return <NoteModel>[];
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
    final uid = _auth.currentUid ?? '';

    // Fetch location safely if not provided
    double? lat = latitude;
    double? lng = longitude;
    if (lat == null && lng == null) {
      final loc = await DeviceLocationService.getCurrentLocation();
      lat = loc.latitude;
      lng = loc.longitude;
    }

    // Fetch device info safely if not provided
    String? dev = deviceInfo;
    if (dev == null || dev.isEmpty) {
      dev = await DeviceLocationService.getDeviceSummary();
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

  /// Soft delete a note (sets is_active to false)
  Future<void> deleteNote(String noteId) async {
    await _collection.doc(noteId).update({
      'is_active': false,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
