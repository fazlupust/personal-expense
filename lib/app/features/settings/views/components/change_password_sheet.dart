import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/auth_service.dart';

Future<void> showChangePasswordSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 480),
    builder: (_) => const ChangePasswordSheet(),
  );
}

class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key});

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _currentError;
  String? _newError;
  String? _confirmError;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final p = context.pal;
    final currentPass = _currentPasswordCtrl.text.trim();
    final newPass = _newPasswordCtrl.text.trim();
    final confirmPass = _confirmPasswordCtrl.text.trim();

    setState(() {
      _currentError = null;
      _newError = null;
      _confirmError = null;
    });

    bool hasError = false;

    if (currentPass.isEmpty) {
      setState(() => _currentError = 'Current password cannot be empty'.tr);
      hasError = true;
    }

    if (newPass.length < 6) {
      setState(() => _newError = 'Password must be at least 6 characters'.tr);
      hasError = true;
    }

    if (confirmPass.isEmpty) {
      setState(() => _confirmError = 'Please confirm your new password'.tr);
      hasError = true;
    } else if (newPass != confirmPass) {
      setState(() => _confirmError = 'New passwords do not match'.tr);
      hasError = true;
    }

    if (hasError) return;

    if (!Get.isRegistered<AuthService>() || !Get.find<AuthService>().isLoggedIn) {
      Get.snackbar('Alert'.tr, 'You must be logged in to change password.'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = Get.find<AuthService>();
      await auth.changePassword(
        currentPassword: currentPass,
        newPassword: newPass,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }

      Get.snackbar(
        'Success'.tr,
        'Password changed successfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: p.income.withOpacity(0.15),
        colorText: p.ink,
        duration: const Duration(seconds: 3),
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Failed to update password. Please try again.'.tr;
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        msg = 'Current password is incorrect'.tr;
        setState(() => _currentError = msg);
      } else if (e.code == 'weak-password') {
        msg = 'Password must be at least 6 characters'.tr;
        setState(() => _newError = msg);
      } else if (e.code == 'requires-recent-login') {
        msg = 'Please sign in again before changing password.'.tr;
      }
      Get.snackbar('Alert'.tr, msg, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Alert'.tr, 'Failed to update password. Please try again.'.tr,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: p.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Bar (Frozen)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(color: p.income),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Change Password'.tr,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Enter your current and new password'.tr,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Form Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Current Password
                      Text(
                        'Current Password'.tr,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.ink),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _currentPasswordCtrl,
                        obscureText: _obscureCurrent,
                        decoration: InputDecoration(
                          hintText: 'Enter current password'.tr,
                          errorText: _currentError,
                          prefixIcon: Icon(Icons.lock_outline, color: p.mute, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                              color: _obscureCurrent ? p.mute : p.income,
                              size: 20,
                            ),
                            tooltip: _obscureCurrent ? 'Show password'.tr : 'Hide password'.tr,
                            onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. New Password
                      Text(
                        'New Password'.tr,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.ink),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _newPasswordCtrl,
                        obscureText: _obscureNew,
                        decoration: InputDecoration(
                          hintText: 'Enter new password (min 6 chars)'.tr,
                          errorText: _newError,
                          prefixIcon: Icon(Icons.lock_reset, color: p.mute, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNew ? Icons.visibility_off : Icons.visibility,
                              color: _obscureNew ? p.mute : p.income,
                              size: 20,
                            ),
                            tooltip: _obscureNew ? 'Show password'.tr : 'Hide password'.tr,
                            onPressed: () => setState(() => _obscureNew = !_obscureNew),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. Confirm New Password
                      Text(
                        'Confirm New Password'.tr,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.ink),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _confirmPasswordCtrl,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          hintText: 'Re-enter new password'.tr,
                          errorText: _confirmError,
                          prefixIcon: Icon(Icons.lock_reset, color: p.mute, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                              color: _obscureConfirm ? p.mute : p.income,
                              size: 20,
                            ),
                            tooltip: _obscureConfirm ? 'Show password'.tr : 'Hide password'.tr,
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons: Cancel and Update Password
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: p.ink,
                                side: BorderSide(color: p.line),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('Cancel'.tr),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: p.income,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      'Update Password'.tr,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
