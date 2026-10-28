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
                  color: p.expense.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout_rounded, color: p.expense, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                'Sign Out Confirmation'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to sign out?'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: p.mute),
              ),
              const SizedBox(height: 22),
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
                      'Sign Out',
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
