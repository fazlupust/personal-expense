import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/services/auth_service.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../../features/transactions/controllers/transactions_controller.dart';
import '../../routes/app_routes.dart';
import '../theme/app_theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.showBackButton = false,
    this.onBack,
    this.leading,
    this.actions,
    this.showLanguageToggle = true,
    this.showThemeToggle = true,
    this.showLogout = true,
  });

  final String? title;
  final Widget? titleWidget;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showLanguageToggle;
  final bool showThemeToggle;
  final bool showLogout;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  void _confirmSignOut(BuildContext context) {
    final p = context.pal;
    final isBn = Get.locale?.languageCode == 'bn';
    final txCtrl = Get.isRegistered<TransactionsController>() ? Get.find<TransactionsController>() : null;
    final unsynced = txCtrl?.unsyncedCount ?? 0;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: (unsynced > 0 ? const Color(0xFFF97316) : p.expense).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    unsynced > 0 ? Icons.warning_amber_rounded : Icons.logout_rounded,
                    color: unsynced > 0 ? const Color(0xFFEA580C) : p.expense,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                unsynced > 0
                    ? (isBn ? 'সতর্কতা: অফলাইন ডাটা রয়েছে!' : 'Warning: Unsynced Data!')
                    : 'Sign Out'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: unsynced > 0 ? const Color(0xFFEA580C) : p.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                unsynced > 0
                    ? (isBn
                        ? 'আপনার $unsyncedটি লেনদেন এখনও ক্লাউড সার্ভারে সিঙ্ক হয়নি! এখন লগআউট করলে এই ডাটা চিরতরে মুছে যাবে।'
                        : 'You have $unsynced transactions not synced to the cloud! Logging out now will permanently erase this data.')
                    : 'Are you sure you want to sign out?'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: unsynced > 0 ? const Color(0xFF9A3412) : p.mute,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              if (unsynced > 0) ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    Get.back();
                    await txCtrl?.syncPendingTransactions();
                  },
                  icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18),
                  label: Text(
                    isBn ? 'এখনই ক্লাউডে সিঙ্ক করুন' : 'Sync to Cloud Now',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F8A5B),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: p.ink,
                        side: BorderSide(color: p.line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Cancel'.tr),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Get.back();
                        if (Get.isRegistered<AuthService>()) {
                          AuthService.to.signOut();
                        } else {
                          Get.offAllNamed(AppRoutes.login);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: p.expense,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        unsynced > 0 ? (isBn ? 'মুছে ফেলে লগআউট' : 'Sign Out Anyway') : 'Sign Out'.tr,
                        style: TextStyle(fontSize: unsynced > 0 ? 11.5 : null),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final canPop = showBackButton || Navigator.canPop(context);

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        border: Border(bottom: BorderSide(color: p.line, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              // Left: Back button, custom leading, or Logo + Title
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 8),
              ] else if (canPop) ...[
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: p.ink,
                  ),
                  onPressed: onBack ?? () => Navigator.maybePop(context),
                  tooltip: 'Back'.tr,
                ),
                const SizedBox(width: 4),
              ] else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 28,
                    height: 28,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.account_balance_wallet, size: 24, color: p.income),
                  ),
                ),
                const SizedBox(width: 10),
              ],

              // Center / Title
              Expanded(
                child: titleWidget ??
                    Text(
                      title?.tr ?? 'My Wallet'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: p.ink,
                        letterSpacing: -0.2,
                      ),
                    ),
              ),

              // Custom user actions if any
              if (actions != null) ...actions!,

              // Right 1: Theme Switcher (Dark / Light)
              if (showThemeToggle && Get.isRegistered<SettingsController>()) ...[
                GetBuilder<SettingsController>(
                  builder: (s) {
                    final isDark = s.isDarkMode;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: s.toggleTheme,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: p.bg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: p.line),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                size: 14,
                                color: isDark ? const Color(0xFFF1C40F) : const Color(0xFF7F8C8D),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isDark ? 'Light'.tr : 'Dark'.tr,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: p.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],

              // Right 2: Language Switcher (EN | বাংলা)
              if (showLanguageToggle && Get.isRegistered<SettingsController>()) ...[
                GetBuilder<SettingsController>(
                  builder: (s) {
                    final isBn = s.langCode == 'bn';
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => s.setLanguage(isBn ? 'en' : 'bn'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: p.bg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: p.line),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.language_rounded,
                                size: 14,
                                color: p.income,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isBn ? 'বাং' : 'EN',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: p.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
              ],

              // Right 2: Logout Button
              if (showLogout && Get.isRegistered<AuthService>()) ...[
                Obx(() {
                  final isLoggedIn = AuthService.to.firebaseUser.value != null;
                  if (!isLoggedIn) return const SizedBox.shrink();

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _confirmSignOut(context),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: p.expense.withOpacity(0.09),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.logout_rounded,
                            size: 18,
                            color: p.expense,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
