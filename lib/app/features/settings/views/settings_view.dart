import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_widgets.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/entry_type.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../transactions/controllers/transactions_controller.dart';
import '../controllers/settings_controller.dart';
import 'components/budget_management_sheet.dart';
import 'components/change_password_sheet.dart';
import 'components/edit_profile_sheet.dart';
import 'components/settings_form_card.dart';

/// "Profile" tab: profile header, lifetime stats, settings, categories, and auth controls.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final hasAuth = Get.isRegistered<AuthService>();
    final auth = hasAuth ? Get.find<AuthService>() : null;

    return GetBuilder<SettingsController>(
      builder: (s) => GetBuilder<TransactionsController>(builder: (tc) {
        final income = tc.sum(tc.entries, EntryType.income);
        final expense = tc.sum(tc.entries, EntryType.expense);
        final balance = income - expense;
        final isBn = s.locale.languageCode == 'bn';

        return ContentWrap(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdaptiveColumns(
                left: [
                  // User Profile Card
                  AppCard(
                    child: hasAuth && auth != null
                        ? Obx(() {
                            final user = auth.userProfile.value;
                            final isLoggedIn = auth.isLoggedIn;
                            final name = user != null
                                ? user.displayName(isBn)
                                : (s.name.isEmpty ? 'Personal Expense User'.tr : s.name);
                            final desig = user?.displayDesignation(isBn) ?? '';
                            final phone = user?.phone ?? '';

                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(color: p.income, shape: BoxShape.circle),
                                      child: Text(
                                        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.ink),
                                          ),
                                          if (desig.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(desig, style: TextStyle(fontSize: 13, color: p.mute)),
                                          ],
                                          if (phone.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(phone, style: TextStyle(fontSize: 12, color: p.mute)),
                                          ],
                                          if (user != null && user.lastLoginDevice != null) ...[
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(Icons.devices, size: 13, color: p.mute),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    user.lastLoginDevice!,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(fontSize: 11, color: p.mute),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                if (isLoggedIn) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppButton(
                                          'Edit Profile',
                                          icon: Icons.edit_outlined,
                                          height: 42,
                                          fontSize: 12.5,
                                          margin: EdgeInsets.zero,
                                          onPressed: () => showEditProfileSheet(context),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: AppButton(
                                          'Change Password',
                                          icon: Icons.lock_reset_rounded,
                                          height: 42,
                                          fontSize: 12.5,
                                          margin: EdgeInsets.zero,
                                          onPressed: () => showChangePasswordSheet(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  AppButton(
                                    'Sign Out',
                                    icon: Icons.logout,
                                    style: AppButtonStyle.cancel,
                                    height: 42,
                                    fontSize: 13,
                                    margin: EdgeInsets.zero,
                                    onPressed: () => _confirmSignOut(context, auth),
                                  ),
                                ] else ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppButton(
                                          'Edit Profile',
                                          icon: Icons.edit_outlined,
                                          height: 42,
                                          fontSize: 12.5,
                                          margin: EdgeInsets.zero,
                                          onPressed: () => showEditProfileSheet(context),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: AppButton(
                                          'Sign In with Phone',
                                          icon: Icons.login,
                                          height: 42,
                                          fontSize: 12.5,
                                          margin: EdgeInsets.zero,
                                          onPressed: () => Get.toNamed(AppRoutes.login),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            );
                          })
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: p.income, shape: BoxShape.circle),
                                    child: Text(
                                      s.name.isEmpty ? '?' : s.name.characters.first.toUpperCase(),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      s.name.isEmpty ? 'Add your name'.tr : s.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.ink),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              AppButton(
                                'Edit Profile',
                                icon: Icons.edit_outlined,
                                height: 42,
                                fontSize: 13,
                                margin: EdgeInsets.zero,
                                onPressed: () => showEditProfileSheet(context),
                              ),
                            ],
                          ),
                  ),

                  // Stats Grid
                  AppCard(
                    child: StatGrid(items: [
                      StatItem('Total entries', Fmt.count(tc.entries.length)),
                      StatItem('Lifetime balance', '${balance < 0 ? '−' : ''}${Fmt.money(balance.abs())}'),
                      StatItem('Total income', Fmt.money(income)),
                      StatItem('Total expense', Fmt.money(expense)),
                    ]),
                  ),

                  // Registered App Users (Visible only to Developers)
                  if (hasAuth && auth != null && auth.isDeveloper)
                    _DeveloperAppUsersCard(auth: auth, p: p, isBn: isBn),

                  // Personal Notes & Debts Link
                  AppCard(
                    flush: true,
                    child: InkWell(
                      onTap: () => Get.toNamed(AppRoutes.notes),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            Icon(Icons.sticky_note_2_outlined, color: p.income),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Personal Notes & Debts'.tr,
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.ink),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Keep personal reminders, debts & loans'.tr,
                                    style: TextStyle(fontSize: 12, color: p.mute),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: p.mute),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Prayer Times & Digital Tasbih Link
                  AppCard(
                    flush: true,
                    child: InkWell(
                      onTap: () => Get.toNamed(AppRoutes.prayerAndTasbih),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            Icon(Icons.nightlight_round, color: p.income),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Prayer Times & Digital Tasbih'.tr,
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.ink),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Daily prayer schedule, next waqt & interactive digital tasbih'.tr,
                                    style: TextStyle(fontSize: 12, color: p.mute),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: p.mute),
                          ],
                        ),
                      ),
                    ),
                  ),


                  // Category Management Link
                  AppCard(
                    flush: true,
                    child: InkWell(
                      onTap: () => Get.toNamed(AppRoutes.categories),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            Icon(Icons.category_outlined, color: p.income),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('Manage categories'.tr,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.ink)),
                            ),
                            Icon(Icons.chevron_right, color: p.mute),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Budget Management Link
                  AppCard(
                    flush: true,
                    child: InkWell(
                      onTap: () => showBudgetManagementSheet(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: p.income.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.account_balance_wallet_outlined, color: p.income, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Budget Management'.tr,
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.ink),
                                      ),
                                      if (s.categoryBudgets.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: p.income.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${s.categoryBudgets.length}',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.income),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.budget > 0
                                        ? '${'Total budget'.tr}: ${AppConstants.currency}${Fmt.money(s.budget)}${s.categoryBudgets.isNotEmpty ? ' · ${s.categoryBudgets.length} ${'category budgets'.tr}' : ''}'
                                        : (s.categoryBudgets.isNotEmpty
                                            ? '${s.categoryBudgets.length} ${'category budgets'.tr}'
                                            : 'Set monthly & category-wise expense limits'.tr),
                                    style: TextStyle(fontSize: 12, color: p.mute),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: p.mute),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Cloud Data Sync Card
                  AppCard(
                    flush: true,
                    child: InkWell(
                      onTap: () async {
                        await tc.refreshTransactions();
                        if (Get.context != null) {
                          final isBn = Get.locale?.languageCode == 'bn';
                          if (tc.unsyncedCount == 0) {
                            Get.snackbar(
                              isBn ? 'সিঙ্ক সম্পন্ন' : 'Sync Complete',
                              isBn
                                  ? 'সব লেনদেন ক্লাউডের সাথে সফলভাবে সিঙ্ক রয়েছে।'
                                  : 'All transactions are synced with the cloud.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: const Color(0xFF1F8A5B),
                              colorText: Colors.white,
                              icon: const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 24),
                              duration: const Duration(seconds: 3),
                            );
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: (tc.unsyncedCount > 0 ? const Color(0xFFF97316) : p.income)
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                tc.unsyncedCount > 0
                                    ? Icons.sync_problem_rounded
                                    : Icons.cloud_sync_rounded,
                                color: tc.unsyncedCount > 0 ? const Color(0xFFEA580C) : p.income,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          isBn ? 'ক্লাউড ডাটা সিঙ্ক' : 'Sync Data with Cloud',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: p.ink),
                                        ),
                                      ),
                                      if (tc.unsyncedCount > 0) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF7ED),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                                color: const Color(0xFFF97316), width: 0.8),
                                          ),
                                          child: Text(
                                            isBn
                                                ? '${Fmt.count(tc.unsyncedCount)}টি অফলাইন'
                                                : '${tc.unsyncedCount} offline',
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFEA580C),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tc.unsyncedCount > 0
                                        ? (isBn
                                            ? '${Fmt.count(tc.unsyncedCount)}টি অফলাইন · সিঙ্ক করতে ট্যাপ করুন'
                                            : '${tc.unsyncedCount} offline · Tap to sync')
                                        : (isBn
                                            ? 'সব ডাটা সিঙ্কড · রিফ্রেশ করতে ট্যাপ করুন'
                                            : 'Synced · Tap to refresh'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: tc.unsyncedCount > 0
                                          ? const Color(0xFFC2410C)
                                          : p.mute,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: p.mute),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                right: [SettingsFormCard(settings: s)],
              ),
            ],
          ),
        );
      }),
    );
  }

  void _confirmSignOut(BuildContext context, AuthService auth) {
    final p = context.pal;
    final isBn = Get.locale?.languageCode == 'bn';
    final txCtrl = Get.isRegistered<TransactionsController>() ? Get.find<TransactionsController>() : null;
    final unsynced = txCtrl?.unsyncedCount ?? 0;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: p.card,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (unsynced > 0 ? const Color(0xFFF97316) : p.expense).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  unsynced > 0 ? Icons.warning_amber_rounded : Icons.logout_rounded,
                  color: unsynced > 0 ? const Color(0xFFEA580C) : p.expense,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                unsynced > 0
                    ? (isBn ? 'সতর্কতা: অফলাইন ডাটা রয়েছে!' : 'Warning: Unsynced Data!')
                    : 'Sign Out Confirmation'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: unsynced > 0 ? const Color(0xFFEA580C) : p.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                unsynced > 0
                    ? (isBn
                        ? 'আপনার $unsyncedটি লেনদেন এখনও ক্লাউড সার্ভারে সিঙ্ক হয়নি! এখন লগআউট করলে এই অফলাইন ডাটা চিরতরে মুছে যাবে। দয়া করে প্রথমে সিঙ্ক করে নিন।'
                        : 'You have $unsynced transactions not synced to the cloud! Logging out now will permanently erase this data. Please sync first.')
                    : 'Are you sure you want to sign out?'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
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
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F8A5B),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: p.line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel'.tr,
                        style: TextStyle(
                          color: p.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      unsynced > 0 ? (isBn ? 'মুছে ফেলে লগআউট' : 'Sign Out Anyway') : 'Sign Out',
                      style: AppButtonStyle.cancel,
                      height: 44,
                      fontSize: 13.5,
                      margin: EdgeInsets.zero,
                      onPressed: () {
                        Get.back();
                        auth.signOut();
                      },
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
}

/// Developer-only card listing all registered users with Name, Designation, and Phone
class _DeveloperAppUsersCard extends StatelessWidget {
  const _DeveloperAppUsersCard({
    required this.auth,
    required this.p,
    required this.isBn,
  });

  final AuthService auth;
  final AppPalette p;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: auth.streamAllUsers(),
      builder: (context, snapshot) {
        final users = snapshot.data ?? [];

        return AppCard(
          flush: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Get.toNamed(AppRoutes.registeredUsers),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: p.income.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.people_alt_rounded, color: p.income, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Registered App Users'.tr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.ink,
                      ),
                    ),
                  ),
                  if (users.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: p.income.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${users.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: p.income,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded, color: p.mute, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
