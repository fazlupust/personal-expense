import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  const NoteModel({
    this.id = '',
    this.userId = '',
    required this.title,
    required this.date,
    this.notes = '',
    this.amount = 0.0,
    this.personName = '',
    this.latitude,
    this.longitude,
    this.deviceInfo,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final DateTime date;
  final String notes;
  final double amount;
  final String personName;
  final double? latitude;
  final double? longitude;
  final String? deviceInfo;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasAmount => amount > 0;
  bool get hasPerson => personName.trim().isNotEmpty;
  bool get hasLocation => latitude != null && longitude != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'amount': amount,
      'person_name': personName,
      'latitude': latitude,
      'longitude': longitude,
      'device_info': deviceInfo,
      'is_active': isActive,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  /// JSON serialization for local caching (SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'date': date.toIso8601String(),
      'notes': notes,
      'amount': amount,
      'person_name': personName,
      'latitude': latitude,
      'longitude': longitude,
      'device_info': deviceInfo,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel.fromMap(json);

  factory NoteModel.fromMap(Map<String, dynamic> map, [String docId = '']) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    return NoteModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      userId: (map['user_id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      date: parseDate(map['date']),
      notes: (map['notes'] ?? '').toString(),
      amount: parseDouble(map['amount']) ?? 0.0,
      personName: (map['person_name'] ?? '').toString(),
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      deviceInfo: map['device_info']?.toString(),
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] != null ? parseDate(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? parseDate(map['updated_at']) : null,
    );
  }

  factory NoteModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return NoteModel.fromMap(data, doc.id);
  }

  NoteModel copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? date,
    String? notes,
    double? amount,
    String? personName,
    double? latitude,
    double? longitude,
    String? deviceInfo,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      amount: amount ?? this.amount,
      personName: personName ?? this.personName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
