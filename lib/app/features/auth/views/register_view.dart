import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../settings/controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';

class RegisterView extends GetView<AuthController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        title: Text('Create Account'.tr, style: TextStyle(color: p.ink, fontWeight: FontWeight.w700)),
        backgroundColor: p.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: p.ink),
          onPressed: () => Get.back(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: GetBuilder<SettingsController>(
                builder: (s) {
                  final isEn = s.langCode == 'en';
                  return Container(
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: p.line),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLangChip(
                          label: 'English',
                          selected: isEn,
                          p: p,
                          onTap: () => s.setLanguage('en'),
                        ),
                        _buildLangChip(
                          label: 'বাংলা',
                          selected: !isEn,
                          p: p,
                          onTap: () => s.setLanguage('bn'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                color: p.card,
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: p.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'User Information'.tr,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.ink),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Fill out the details to create your account'.tr,
                        style: TextStyle(fontSize: 13, color: p.mute),
                      ),
                      const SizedBox(height: 20),

                      // Error message banner
                      Obx(() {
                        if (controller.errorMessage.isEmpty) return const SizedBox.shrink();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: p.expense.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: p.expense.withOpacity(0.3)),
                          ),
                          child: Text(
                            controller.errorMessage.value,
                            style: TextStyle(color: p.expense, fontSize: 13, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }),

                      // Phone Field
                      Text('Phone Number *'.tr, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.ink)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: controller.phoneRegCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '01XXXXXXXXX',
                          prefixIcon: Icon(Icons.phone_outlined, color: p.mute),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Password Field
                      Text('Password *'.tr, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.ink)),
                      const SizedBox(height: 6),
                      Obx(() => TextField(
                            controller: controller.passwordRegCtrl,
                            obscureText: controller.obscurePassword.value,
                            decoration: InputDecoration(
                              hintText: 'Minimum 6 characters',
                              prefixIcon: Icon(Icons.lock_outline, color: p.mute),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  controller.obscurePassword.value ? Icons.visibility_off : Icons.visibility,
                                  color: p.mute,
                                ),
                                onPressed: controller.togglePasswordVisibility,
                              ),
                            ),
                          )),
                      const SizedBox(height: 14),

                      // English Name
                      Text('English Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.ink)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: controller.nameEnCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Fazlu Karim',
                          prefixIcon: Icon(Icons.person_outline, color: p.mute),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // বাংলা নাম
                      Text('বাংলা নাম *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.ink)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: controller.nameBnCtrl,
                        decoration: InputDecoration(
                          hintText: 'যেমন: ফজলু করিম',
                          prefixIcon: Icon(Icons.badge_outlined, color: p.mute),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // English Designation
                      Text('English Designation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.ink)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: controller.designationEnCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Software Engineer',
                          prefixIcon: Icon(Icons.work_outline, color: p.mute),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // বাংলা পদবি
                      Text('বাংলা পদবি', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.ink)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: controller.designationBnCtrl,
                        decoration: InputDecoration(
                          hintText: 'যেমন: সফটওয়্যার ইঞ্জিনিয়ার',
                          prefixIcon: Icon(Icons.business_center_outlined, color: p.mute),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Address
                      Text('Address (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.ink)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: controller.addressEnCtrl,
                        decoration: const InputDecoration(
                          hintText: 'City, Area (e.g. Dhaka, Bangladesh)',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      Obx(() => SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: controller.auth.isLoading.value ? null : controller.register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: p.income,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: controller.auth.isLoading.value
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Text(
                                      'Complete Registration'.tr,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLangChip({
    required String label,
    required bool selected,
    required AppPalette p,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? p.income : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : p.mute,
          ),
        ),
      ),
    );
  }
}
