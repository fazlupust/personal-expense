import 'package:cloud_firestore/cloud_firestore.dart';

/// Day-wise Zikir Log model stored in Firestore under:
/// users/{uid}/tasbih_entries/{date}_{jikir_id}
class TasbihEntryModel {
  final String id; // format: "{date}_{jikir_id}", e.g. "2026-10-27_subhanallah"
  final String userId;
  final String jikirId;
  final String jikirName;
  final String jikirNameEn;
  final String arabic;
  final String category;
  final int jikirCount;
  final String date; // format: "yyyy-MM-dd"
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TasbihEntryModel({
    required this.id,
    required this.userId,
    required this.jikirId,
    required this.jikirName,
    required this.jikirNameEn,
    required this.arabic,
    required this.category,
    required this.jikirCount,
    required this.date,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toFirestore({bool isNew = false}) {
    final map = <String, dynamic>{
      'id': id,
      'user_id': userId,
      'jikir_id': jikirId,
      'jikir_name': jikirName,
      'jikir_name_en': jikirNameEn,
      'arabic': arabic,
      'category': category,
      'jikir_count': jikirCount,
      'jikircound': jikirCount, // Alias requested by user
      'date': date,
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (isNew) {
      map['created_at'] = FieldValue.serverTimestamp();
    }
    return map;
  }

  factory TasbihEntryModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TasbihEntryModel.fromMap(doc.id, data);
  }

  factory TasbihEntryModel.fromMap(String docId, Map<String, dynamic> data) {
    return TasbihEntryModel(
      id: docId,
      userId: data['user_id']?.toString() ?? '',
      jikirId: data['jikir_id']?.toString() ?? '',
      jikirName: data['jikir_name']?.toString() ?? '',
      jikirNameEn: data['jikir_name_en']?.toString() ?? '',
      arabic: data['arabic']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      jikirCount: (data['jikir_count'] as num?)?.toInt() ??
          (data['jikircound'] as num?)?.toInt() ??
          0,
      date: data['date']?.toString() ?? '',
      createdAt: data['created_at'] is Timestamp
          ? (data['created_at'] as Timestamp).toDate()
          : data['created_at'] is DateTime
              ? data['created_at'] as DateTime
              : null,
      updatedAt: data['updated_at'] is Timestamp
          ? (data['updated_at'] as Timestamp).toDate()
          : data['updated_at'] is DateTime
              ? data['updated_at'] as DateTime
              : null,
    );
  }

  TasbihEntryModel copyWith({
    String? id,
    String? userId,
    String? jikirId,
    String? jikirName,
    String? jikirNameEn,
    String? arabic,
    String? category,
    int? jikirCount,
    String? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TasbihEntryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      jikirId: jikirId ?? this.jikirId,
      jikirName: jikirName ?? this.jikirName,
      jikirNameEn: jikirNameEn ?? this.jikirNameEn,
      arabic: arabic ?? this.arabic,
      category: category ?? this.category,
      jikirCount: jikirCount ?? this.jikirCount,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
