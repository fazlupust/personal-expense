import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'entry_type.dart';

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryNameBn,
    required this.categoryNameEn,
    required this.type,
    required this.amount,
    this.noteBn,
    this.noteEn,
    required this.date,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
    this.account = 'Cash',
    this.latitude,
    this.longitude,
    this.deviceInfo,
  });

  final String id;
  final String userId;
  final String categoryId;
  final String categoryNameBn;
  final String categoryNameEn;
  final EntryType type;
  final double amount;
  final String? noteBn;
  final String? noteEn;
  final DateTime date; // transaction_date
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String account;
  final double? latitude;
  final double? longitude;
  final String? deviceInfo;

  String categoryName(bool isBn) =>
      isBn ? (categoryNameBn.isNotEmpty ? categoryNameBn : categoryNameEn) : (categoryNameEn.isNotEmpty ? categoryNameEn : categoryNameBn);

  String noteText(bool isBn) {
    if (isBn && (noteBn?.isNotEmpty ?? false)) return noteBn!;
    if (noteEn?.isNotEmpty ?? false) return noteEn!;
    return noteBn ?? '';
  }

  // Backward compatibility getters for existing UI
  String get category {
    final isBn = Get.locale?.languageCode == 'bn';
    if (isBn && categoryNameBn.isNotEmpty) return categoryNameBn;
    if (categoryNameEn.isNotEmpty) return categoryNameEn;
    return categoryNameBn;
  }

  String get note {
    final isBn = Get.locale?.languageCode == 'bn';
    if (isBn && (noteBn?.isNotEmpty ?? false)) return noteBn!;
    if (noteEn?.isNotEmpty ?? false) return noteEn!;
    return noteBn ?? '';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'category_name_bn': categoryNameBn,
      'category_name_en': categoryNameEn,
      'type': type.name,
      'amount': amount,
      'note_bn': noteBn,
      'note_en': noteEn,
      'transaction_date': Timestamp.fromDate(date),
      'is_deleted': isDeleted,
      'account': account,
      'latitude': latitude,
      'longitude': longitude,
      'device_info': deviceInfo,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  /// JSON serialization for export/backup (ISO-8601 strings, encodable by standard jsonEncode)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'category_name_bn': categoryNameBn,
      'category_name_en': categoryNameEn,
      'type': type.name,
      'amount': amount,
      'note_bn': noteBn,
      'note_en': noteEn,
      'date': date.toIso8601String(),
      'transaction_date': date.toIso8601String(),
      'is_deleted': isDeleted,
      'account': account,
      'latitude': latitude,
      'longitude': longitude,
      'device_info': deviceInfo,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    double parseAmount(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    bool parseBool(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      if (val is num) return val != 0;
      if (val is String) {
        final lower = val.trim().toLowerCase();
        return lower == 'true' || lower == '1';
      }
      return false;
    }

    final typeStr = (map['type']?.toString().toLowerCase()) ?? 'expense';
    final entryType = typeStr == 'income' ? EntryType.income : EntryType.expense;

    return TransactionModel(
      id: (map['id']?.toString()) ?? docId,
      userId: (map['user_id']?.toString()) ?? '',
      categoryId: (map['category_id']?.toString()) ?? '',
      categoryNameBn: (map['category_name_bn']?.toString()) ?? '',
      categoryNameEn: (map['category_name_en']?.toString()) ?? '',
      type: entryType,
      amount: parseAmount(map['amount']),
      noteBn: map['note_bn']?.toString(),
      noteEn: map['note_en']?.toString(),
      date: parseDate(map['transaction_date'] ?? map['date']),
      isDeleted: parseBool(map['is_deleted']),
      account: (map['account']?.toString()) ?? 'Cash',
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      deviceInfo: map['device_info']?.toString(),
      createdAt: map['created_at'] != null ? parseDate(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? parseDate(map['updated_at']) : null,
    );
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      return TransactionModel.fromMap(doc.data() ?? {}, doc.id);
    } catch (_) {
      return TransactionModel.fromMap({}, doc.id);
    }
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? categoryNameBn,
    String? categoryNameEn,
    EntryType? type,
    double? amount,
    String? noteBn,
    String? noteEn,
    DateTime? date,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? account,
    double? latitude,
    double? longitude,
    String? deviceInfo,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      categoryNameBn: categoryNameBn ?? this.categoryNameBn,
      categoryNameEn: categoryNameEn ?? this.categoryNameEn,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      noteBn: noteBn ?? this.noteBn,
      noteEn: noteEn ?? this.noteEn,
      date: date ?? this.date,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      account: account ?? this.account,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }
}
