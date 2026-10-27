import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../models/user_model.dart';
import 'device_location_service.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find<AuthService>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Rx<User?> firebaseUser = Rx<User?>(null);
  final Rx<UserModel?> userProfile = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;

  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;
  bool get isLoggedIn => _auth.currentUser != null;

  bool get isDeveloper {
    if (userProfile.value?.isDeveloper == true) return true;
    if (userProfile.value?.role == 'developer') return true;
    if (UserModel.isDevPhone(userProfile.value?.phone)) return true;
    final phone = currentUser?.phoneNumber;
    if (UserModel.isDevPhone(phone)) return true;
    final emailPrefix = currentUser?.email?.split('@').first;
    if (UserModel.isDevPhone(emailPrefix)) return true;
    return false;
  }

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user != null) {
      await fetchUserProfile(user.uid);
    } else {
      userProfile.value = null;
    }
  }

  /// Converts a phone number (e.g. 01712345678) into a Firebase Auth compatible email
  String _phoneToEmail(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    return '$cleaned@personalexpense.app';
  }

  /// Fetch user document from Firestore 'users' collection
  Future<UserModel?> fetchUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        var profile = UserModel.fromFirestore(doc);
        // Ensure developer role for dev phone
        if (UserModel.isDevPhone(profile.phone) || UserModel.isDevPhone(currentUser?.email?.split('@').first)) {
          if (profile.role != 'developer') {
            profile = profile.copyWith(role: 'developer');
            try {
              await _db.collection('users').doc(uid).set({'role': 'developer'}, SetOptions(merge: true));
            } catch (_) {}
          }
        }
        // Backfill userNo for existing user if missing
        if (profile.userNo == null) {
          try {
            final countSnap = await _db.collection('users').count().get();
            final assigned = countSnap.count ?? 1;
            await _db.collection('users').doc(uid).set({'user_no': assigned}, SetOptions(merge: true));
            profile = profile.copyWith(userNo: assigned);
          } catch (_) {}
        }
        userProfile.value = profile;
        return profile;
      }
    } catch (e) {
      // ignore or log
    }
    return null;
  }

  /// Record user's device info and location (null if off or denied) safely upon login
  Future<void> _recordLoginMetadata(String uid) async {
    try {
      final loc = await DeviceLocationService.getCurrentLocation();
      final device = await DeviceLocationService.getDeviceSummary();

      await _db.collection('users').doc(uid).set({
        'last_login_at': FieldValue.serverTimestamp(),
        'last_login_device': device,
        'last_login_latitude': loc.latitude,
        'last_login_longitude': loc.longitude,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to record login metadata: $e');
    }
  }

  /// Register new user with Phone, Password and Profile details
  Future<UserModel?> registerWithPhone({
    required String phone,
    required String password,
    required String nameBn,
    required String nameEn,
    required String designationBn,
    required String designationEn,
    String? addressBn,
    String? addressEn,
    String? email,
    String role = 'user',
  }) async {
    isLoading.value = true;
    try {
      final virtualEmail = _phoneToEmail(phone);
      final cred = await _auth.createUserWithEmailAndPassword(
        email: virtualEmail,
        password: password,
      );

      final uid = cred.user!.uid;

      // Safely fetch device and location
      final loc = await DeviceLocationService.getCurrentLocation();
      final device = await DeviceLocationService.getDeviceSummary();

      // Sequential user ID (1, 2, 3, 4...)
      int nextUserNo = 1;
      try {
        final countSnap = await _db.collection('users').count().get();
        nextUserNo = (countSnap.count ?? 0) + 1;
      } catch (_) {
        nextUserNo = 1;
      }

      final assignedRole = UserModel.isDevPhone(phone) ? 'developer' : role;

      final newProfile = UserModel(
        uid: uid,
        userNo: nextUserNo,
        nameBn: nameBn,
        nameEn: nameEn,
        designationBn: designationBn,
        designationEn: designationEn,
        phone: phone,
        email: email,
        addressBn: addressBn,
        addressEn: addressEn,
        role: assignedRole,
        isActive: true,
        lastLoginLatitude: loc.latitude,
        lastLoginLongitude: loc.longitude,
        lastLoginDevice: device,
        lastLoginAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save into 'users' collection
      await _db.collection('users').doc(uid).set(newProfile.toMap());
      userProfile.value = newProfile;
      return newProfile;
    } finally {
      isLoading.value = false;
    }
  }

  /// Login with Phone and Password
  Future<UserCredential> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    isLoading.value = true;
    try {
      final virtualEmail = _phoneToEmail(phone);
      final cred = await _auth.signInWithEmailAndPassword(
        email: virtualEmail,
        password: password,
      );
      if (cred.user != null) {
        await _recordLoginMetadata(cred.user!.uid);
        var profile = await fetchUserProfile(cred.user!.uid);
        if (UserModel.isDevPhone(phone) && profile != null && profile.role != 'developer') {
          profile = profile.copyWith(role: 'developer');
          await _db.collection('users').doc(cred.user!.uid).set({'role': 'developer'}, SetOptions(merge: true));
          userProfile.value = profile;
        }
      }
      return cred;
    } finally {
      isLoading.value = false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    userProfile.value = null;
    Get.offAllNamed(AppRoutes.login);
  }

  /// Update user profile in Firestore
  Future<void> updateProfile(UserModel updated) async {
    if (currentUid == null) return;
    await _db.collection('users').doc(currentUid).update(updated.toMap());
    userProfile.value = updated;
  }

  /// Change password for currently logged-in user
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user is currently logged in.',
      );
    }

    final email = user.email;
    if (email == null) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'User email not found.',
      );
    }

    isLoading.value = true;
    try {
      // Re-authenticate user with current password
      final cred = EmailAuthProvider.credential(email: email, password: currentPassword);
      await user.reauthenticateWithCredential(cred);

      // Update password
      await user.updatePassword(newPassword);
    } finally {
      isLoading.value = false;
    }
  }

  /// Stream all registered users (for developer view)
  Stream<List<UserModel>> streamAllUsers() {
    return _db.collection('users').snapshots().map((snap) {
      final list = snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
      list.sort((a, b) {
        if (a.userNo != null && b.userNo != null) {
          return a.userNo!.compareTo(b.userNo!);
        }
        if (a.userNo != null) return -1;
        if (b.userNo != null) return 1;
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }
}
