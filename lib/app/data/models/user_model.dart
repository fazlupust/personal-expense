import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.uid,
    this.userNo,
    required this.nameBn,
    required this.nameEn,
    required this.designationBn,
    required this.designationEn,
    this.phone,
    this.email,
    this.addressBn,
    this.addressEn,
    this.role = 'user',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.lastLoginLatitude,
    this.lastLoginLongitude,
    this.lastLoginDevice,
    this.lastLoginAt,
    this.transactionCount,
  });

  final String uid;
  final int? userNo; // Sequential numeric user ID e.g. 1, 2, 3...
  final int? transactionCount;
  final String nameBn;
  final String nameEn;
  final String designationBn;
  final String designationEn;
  final String? phone;
  final String? email;
  final String? addressBn;
  final String? addressEn;
  final String role; // 'user' | 'admin' | 'developer'
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? lastLoginLatitude;
  final double? lastLoginLongitude;
  final String? lastLoginDevice;
  final DateTime? lastLoginAt;

  static bool isDevPhone(String? p) {
    if (p == null) return false;
    final cleaned = p.replaceAll(RegExp(r'\D'), '');
    return cleaned == '01744309649' || cleaned == '8801744309649';
  }

  bool get isAdmin => role == 'admin';
  bool get isDeveloper => role == 'developer' || role == 'admin' || isDevPhone(phone);

  String displayName(bool isBn) =>
      isBn ? (nameBn.isNotEmpty ? nameBn : nameEn) : (nameEn.isNotEmpty ? nameEn : nameBn);

  String displayDesignation(bool isBn) => isBn
      ? (designationBn.isNotEmpty ? designationBn : designationEn)
      : (designationEn.isNotEmpty ? designationEn : designationBn);

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'user_no': userNo,
      'name_bn': nameBn,
      'name_en': nameEn,
      'designation_bn': designationBn,
      'designation_en': designationEn,
      'phone': phone,
      'email': email,
      'address_bn': addressBn,
      'address_en': addressEn,
      'role': role,
      'is_active': isActive,
      if (transactionCount != null) 'transaction_count': transactionCount,
      'last_login_latitude': lastLoginLatitude,
      'last_login_longitude': lastLoginLongitude,
      'last_login_device': lastLoginDevice,
      'last_login_at': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    double? parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    int? parseUserNo(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }

    int? parseCount(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }

    return UserModel(
      uid: (map['uid'] as String?) ?? docId,
      userNo: parseUserNo(map['user_no']),
      transactionCount: parseCount(map['transaction_count']),
      nameBn: (map['name_bn'] as String?) ?? '',
      nameEn: (map['name_en'] as String?) ?? '',
      designationBn: (map['designation_bn'] as String?) ?? '',
      designationEn: (map['designation_en'] as String?) ?? '',
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      addressBn: map['address_bn'] as String?,
      addressEn: map['address_en'] as String?,
      role: (map['role'] as String?) ?? 'user',
      isActive: (map['is_active'] as bool?) ?? true,
      lastLoginLatitude: parseDouble(map['last_login_latitude']),
      lastLoginLongitude: parseDouble(map['last_login_longitude']),
      lastLoginDevice: map['last_login_device'] as String?,
      lastLoginAt: parseDate(map['last_login_at']),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserModel.fromMap(data, doc.id);
  }

  UserModel copyWith({
    String? uid,
    int? userNo,
    int? transactionCount,
    String? nameBn,
    String? nameEn,
    String? designationBn,
    String? designationEn,
    String? phone,
    String? email,
    String? addressBn,
    String? addressEn,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? lastLoginLatitude,
    double? lastLoginLongitude,
    String? lastLoginDevice,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      userNo: userNo ?? this.userNo,
      transactionCount: transactionCount ?? this.transactionCount,
      nameBn: nameBn ?? this.nameBn,
      nameEn: nameEn ?? this.nameEn,
      designationBn: designationBn ?? this.designationBn,
      designationEn: designationEn ?? this.designationEn,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      addressBn: addressBn ?? this.addressBn,
      addressEn: addressEn ?? this.addressEn,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      lastLoginLatitude: lastLoginLatitude ?? this.lastLoginLatitude,
      lastLoginLongitude: lastLoginLongitude ?? this.lastLoginLongitude,
      lastLoginDevice: lastLoginDevice ?? this.lastLoginDevice,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
