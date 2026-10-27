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
              const PageTitle('Profile'),
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
                                        child: ElevatedButton.icon(
                                          onPressed: () => showEditProfileSheet(context),
                                          icon: const Icon(Icons.edit_outlined, size: 17, color: Colors.white),
                                          label: Text('Edit Profile'.tr),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: p.income,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => showChangePasswordSheet(context),
                                          icon: const Icon(Icons.lock_reset_rounded, size: 17, color: Colors.white),
                                          label: Text('Change Password'.tr),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: p.income,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => auth.signOut(),
                                      icon: const Icon(Icons.logout, size: 17),
                                      label: Text('Sign Out'.tr),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: p.expense,
                                        side: BorderSide(color: p.expense.withOpacity(0.4)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => showEditProfileSheet(context),
                                          icon: const Icon(Icons.edit_outlined, size: 17, color: Colors.white),
                                          label: Text('Edit Profile'.tr),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: p.income,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => Get.toNamed(AppRoutes.login),
                                          icon: const Icon(Icons.login, size: 17, color: Colors.white),
                                          label: Text('Sign In with Phone'.tr),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: p.income,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
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
                              ElevatedButton.icon(
                                onPressed: () => showEditProfileSheet(context),
                                icon: const Icon(Icons.edit_outlined, size: 17, color: Colors.white),
                                label: Text('Edit Profile'.tr),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: p.income,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
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
        final isLoading = snapshot.connectionState == ConnectionState.waiting && users.isEmpty;

        return AppCard(
          flush: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header (Tapping opens full Registered Users Page)
              InkWell(
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
              Divider(height: 1, color: p.line),

              // Content
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: p.income),
                    ),
                  ),
                )
              else if (users.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No registered users found'.tr,
                      style: TextStyle(fontSize: 13, color: p.mute),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => Divider(height: 1, indent: 64, color: p.line),
                  itemBuilder: (context, i) {
                    final u = users[i];
                    final name = u.displayName(isBn);
                    final desig = u.displayDesignation(isBn);
                    final phone = u.phone ?? '';

                    return InkWell(
                      onTap: () => Get.toNamed(AppRoutes.registeredUsers),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                          // Avatar
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: p.income.withOpacity(0.15),
                            child: Text(
                              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: p.income,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Name, Designation, Phone
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        name.isEmpty ? 'Personal Expense User'.tr : name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: p.ink,
                                        ),
                                      ),
                                    ),
                                    if (u.userNo != null) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: p.bg,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: p.line),
                                        ),
                                        child: Text(
                                          '#${u.userNo}',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: p.mute),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (desig.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    desig,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: p.mute),
                                  ),
                                ],
                                if (phone.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(Icons.phone_outlined, size: 12, color: p.income),
                                      const SizedBox(width: 4),
                                      Text(
                                        phone,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: p.ink,
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
                    ),
                  );
                },
                ),
            ],
          ),
        );
      },
    );
  }
}
