import 'package:cloud_firestore/cloud_firestore.dart';
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
  String get category => categoryNameEn.isNotEmpty ? categoryNameEn : categoryNameBn;
  String get note => noteEn ?? noteBn ?? '';

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

  factory TransactionModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    double? parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    final typeStr = (map['type'] as String?) ?? 'expense';
    final entryType = typeStr == 'income' ? EntryType.income : EntryType.expense;

    return TransactionModel(
      id: (map['id'] as String?) ?? docId,
      userId: (map['user_id'] as String?) ?? '',
      categoryId: (map['category_id'] as String?) ?? '',
      categoryNameBn: (map['category_name_bn'] as String?) ?? '',
      categoryNameEn: (map['category_name_en'] as String?) ?? '',
      type: entryType,
      amount: ((map['amount'] as num?) ?? 0).toDouble(),
      noteBn: map['note_bn'] as String?,
      noteEn: map['note_en'] as String?,
      date: parseDate(map['transaction_date'] ?? map['date']),
      isDeleted: (map['is_deleted'] as bool?) ?? false,
      account: (map['account'] as String?) ?? 'Cash',
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      deviceInfo: map['device_info'] as String?,
      createdAt: map['created_at'] != null ? parseDate(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? parseDate(map['updated_at']) : null,
    );
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return TransactionModel.fromMap(doc.data() ?? {}, doc.id);
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
