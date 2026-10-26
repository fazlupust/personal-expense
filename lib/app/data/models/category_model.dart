import 'package:cloud_firestore/cloud_firestore.dart';
import 'entry_type.dart';

class CategoryModel {
  const CategoryModel({
    this.id = '',
    this.nameBn = '',
    this.nameEn = '',
    String? name,
    required this.type,
    this.isActive = true,
    this.isDefault = false,
    this.createdBy = '',
    this.updatedBy = '',
    this.createdAt,
    this.updatedAt,
    this.emoji = '🏷️',
  }) : _name = name;

  final String? _name;
  final String id;
  final String nameBn;
  final String nameEn;
  final EntryType type;
  final bool isActive;
  final bool isDefault;
  final String createdBy;
  final String updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String emoji;

  String displayName(bool isBn) {
    if (isBn && nameBn.isNotEmpty) return nameBn;
    if (nameEn.isNotEmpty) return nameEn;
    return _name ?? (nameBn.isNotEmpty ? nameBn : '');
  }

  // Backward compatibility getter for existing UI widgets
  String get name => _name ?? (nameEn.isNotEmpty ? nameEn : nameBn);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_bn': nameBn.isNotEmpty ? nameBn : (_name ?? ''),
      'name_en': nameEn.isNotEmpty ? nameEn : (_name ?? ''),
      'type': type.name,
      'is_active': isActive,
      'is_default': isDefault,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'emoji': emoji,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final typeStr = (map['type'] as String?) ?? 'expense';
    final entryType = typeStr == 'income' ? EntryType.income : EntryType.expense;

    return CategoryModel(
      id: (map['id'] as String?) ?? docId,
      nameBn: (map['name_bn'] as String?) ?? '',
      nameEn: (map['name_en'] as String?) ?? '',
      type: entryType,
      isActive: (map['is_active'] as bool?) ?? true,
      isDefault: (map['is_default'] as bool?) ?? false,
      createdBy: (map['created_by'] as String?) ?? '',
      updatedBy: (map['updated_by'] as String?) ?? '',
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
      emoji: (map['emoji'] as String?) ?? '🏷️',
    );
  }

  factory CategoryModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return CategoryModel.fromMap(doc.data() ?? {}, doc.id);
  }
}
