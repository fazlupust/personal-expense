import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/auth_service.dart';
import '../../controllers/settings_controller.dart';

Future<void> showEditProfileSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 520),
    builder: (_) => const EditProfileSheet(),
  );
}

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _nameEnCtrl = TextEditingController();
  final _nameBnCtrl = TextEditingController();
  final _designationEnCtrl = TextEditingController();
  final _designationBnCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressEnCtrl = TextEditingController();
  final _addressBnCtrl = TextEditingController();

  String? _nameError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Get.isRegistered<AuthService>() ? AuthService.to.userProfile.value : null;
    final s = Get.isRegistered<SettingsController>() ? SettingsController.to : null;

    _nameEnCtrl.text = user?.nameEn ?? s?.name ?? '';
    _nameBnCtrl.text = user?.nameBn ?? '';
    _designationEnCtrl.text = user?.designationEn ?? '';
    _designationBnCtrl.text = user?.designationBn ?? '';
    _emailCtrl.text = user?.email ?? '';
    _addressEnCtrl.text = user?.addressEn ?? '';
    _addressBnCtrl.text = user?.addressBn ?? '';
  }

  @override
  void dispose() {
    _nameEnCtrl.dispose();
    _nameBnCtrl.dispose();
    _designationEnCtrl.dispose();
    _designationBnCtrl.dispose();
    _emailCtrl.dispose();
    _addressEnCtrl.dispose();
    _addressBnCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nameEn = _nameEnCtrl.text.trim();
    final nameBn = _nameBnCtrl.text.trim();

    if (nameEn.isEmpty && nameBn.isEmpty) {
      setState(() {
        _nameError = 'Enter a valid name.'.tr;
      });
      return;
    }

    setState(() {
      _nameError = null;
      _isLoading = true;
    });

    try {
      final auth = Get.isRegistered<AuthService>() ? AuthService.to : null;
      final current = auth?.userProfile.value;
      final effectiveName = nameEn.isNotEmpty ? nameEn : nameBn;

      if (current != null && auth != null) {
        final updated = current.copyWith(
          nameEn: nameEn.isNotEmpty ? nameEn : nameBn,
          nameBn: nameBn.isNotEmpty ? nameBn : nameEn,
          designationEn: _designationEnCtrl.text.trim(),
          designationBn: _designationBnCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          addressEn: _addressEnCtrl.text.trim(),
          addressBn: _addressBnCtrl.text.trim(),
          updatedAt: DateTime.now(),
        );

        await auth.updateProfile(updated);
      }

      if (Get.isRegistered<SettingsController>()) {
        final s = SettingsController.to;
        s.name = effectiveName;
        s.nameCtrl.text = effectiveName;
        s.saveProfile();
      }

      if (mounted) {
        Navigator.of(context).pop();
        if (Get.context != null) {
          Get.snackbar(
            'Success'.tr,
            'Profile updated successfully'.tr,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (Get.context != null) {
          Get.snackbar(
            'Error'.tr,
            e.toString(),
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final user = Get.isRegistered<AuthService>() ? AuthService.to.userProfile.value : null;
    final phone = user?.phone ?? '';

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: p.income.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.person_outline_rounded, color: p.income, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Edit Profile'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: p.ink,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: p.mute),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Phone indicator (Read only)
            if (phone.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: p.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.line),
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone_android_rounded, size: 18, color: p.mute),
                    const SizedBox(width: 10),
                    Text(
                      phone,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.ink),
                    ),
                    const Spacer(),
                    if (user != null && user.isDeveloper)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: p.income.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'DEVELOPER',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: p.income),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // English Name
            _buildField(
              label: 'Full Name (English)'.tr,
              controller: _nameEnCtrl,
              icon: Icons.badge_outlined,
              p: p,
              errorText: _nameError,
            ),
            const SizedBox(height: 12),

            // Bengali Name
            _buildField(
              label: 'Full Name (বাংলা)'.tr,
              controller: _nameBnCtrl,
              icon: Icons.badge_rounded,
              p: p,
            ),
            const SizedBox(height: 12),

            // Designation Row
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: 'Designation (EN)'.tr,
                    controller: _designationEnCtrl,
                    icon: Icons.work_outline_rounded,
                    p: p,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildField(
                    label: 'Designation (বাংলা)'.tr,
                    controller: _designationBnCtrl,
                    icon: Icons.work_rounded,
                    p: p,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Email
            _buildField(
              label: 'Email Address'.tr,
              controller: _emailCtrl,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              p: p,
            ),
            const SizedBox(height: 12),

            // Address English
            _buildField(
              label: 'Address (English)'.tr,
              controller: _addressEnCtrl,
              icon: Icons.location_on_outlined,
              p: p,
            ),
            const SizedBox(height: 12),

            // Address Bengali
            _buildField(
              label: 'Address (বাংলা)'.tr,
              controller: _addressBnCtrl,
              icon: Icons.location_on_rounded,
              p: p,
            ),
            const SizedBox(height: 22),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: p.income,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Update Profile'.tr,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required AppPalette p,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.ink),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: 14, color: p.ink),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: p.mute),
            filled: true,
            fillColor: p.bg,
            errorText: errorText,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: p.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: p.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: p.income, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
