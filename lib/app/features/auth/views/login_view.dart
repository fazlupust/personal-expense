import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../../settings/controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                color: p.card,
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: p.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Language Switcher (EN / বাংলা)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GetBuilder<SettingsController>(
                            builder: (s) {
                              final isEn = s.langCode == 'en';
                              return Container(
                                decoration: BoxDecoration(
                                  color: p.bg,
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
                        ],
                      ),
                      const SizedBox(height: 12),

                      // App Icon & Header
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: p.income.withOpacity(0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 72,
                              height: 72,
                              errorBuilder: (_, __, ___) => Container(
                                width: 72,
                                height: 72,
                                color: p.income,
                                alignment: Alignment.center,
                                child: const Icon(Icons.account_balance_wallet, size: 36, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Welcome Back'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: p.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in with your phone & password'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: p.mute),
                      ),
                      const SizedBox(height: 24),

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
                      Text('Phone Number'.tr, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.ink)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: controller.phoneLoginCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '01XXXXXXXXX',
                          prefixIcon: Icon(Icons.phone_outlined, color: p.mute),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      Text('Password'.tr, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.ink)),
                      const SizedBox(height: 6),
                      Obx(() => TextField(
                            controller: controller.passwordLoginCtrl,
                            obscureText: controller.obscurePassword.value,
                            decoration: InputDecoration(
                              hintText: '••••••••',
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
                      const SizedBox(height: 24),

                      // Login Button
                      Obx(() => SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: controller.auth.isLoading.value ? null : controller.login,
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
                                      'Log In'.tr,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                            ),
                          )),
                      const SizedBox(height: 18),

                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? ".tr, style: TextStyle(color: p.mute, fontSize: 13)),
                          GestureDetector(
                            onTap: () => Get.toNamed(AppRoutes.register),
                            child: Text(
                              'Register'.tr,
                              style: TextStyle(color: p.income, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: () => Get.offAllNamed(AppRoutes.navigation),
                          child: Text(
                            'Continue as Guest'.tr,
                            style: TextStyle(color: p.mute, fontSize: 13),
                          ),
                        ),
                      ),
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
