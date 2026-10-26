import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_widgets.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/entry_type.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../transactions/controllers/transactions_controller.dart';
import '../controllers/settings_controller.dart';
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
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.ink),
                                                ),
                                              ),
                                              if (user != null && user.userNo != null) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: p.ink.withOpacity(0.08),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    '#${user.userNo}',
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: p.ink),
                                                  ),
                                                ),
                                              ],
                                              if (user != null && user.role != 'user') ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: p.income.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    user.role.toUpperCase(),
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: p.income),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (desig.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(desig, style: TextStyle(fontSize: 13, color: p.mute)),
                                          ],
                                          if (phone.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(phone, style: TextStyle(fontSize: 12, color: p.mute)),
                                          ],
                                          if (user != null && (user.lastLoginDevice != null || user.lastLoginLatitude != null)) ...[
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(Icons.devices, size: 13, color: p.mute),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    user.lastLoginDevice ?? 'Device logged in',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(fontSize: 11, color: p.mute),
                                                  ),
                                                ),
                                                if (user.lastLoginLatitude != null && user.lastLoginLongitude != null) ...[
                                                  const SizedBox(width: 6),
                                                  Text('·', style: TextStyle(color: p.mute)),
                                                  const SizedBox(width: 6),
                                                  Icon(Icons.location_on, size: 13, color: p.income),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    '${user.lastLoginLatitude!.toStringAsFixed(2)}, ${user.lastLoginLongitude!.toStringAsFixed(2)}',
                                                    style: TextStyle(fontSize: 11, color: p.mute),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          if (isLoggedIn) {
                                            auth.signOut();
                                          } else {
                                            Get.toNamed(AppRoutes.login);
                                          }
                                        },
                                        icon: Icon(isLoggedIn ? Icons.logout : Icons.login, size: 18),
                                        label: Text(isLoggedIn ? 'Sign Out'.tr : 'Sign In with Phone'.tr),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: isLoggedIn ? p.expense : p.income,
                                          side: BorderSide(color: isLoggedIn ? p.expense.withOpacity(0.4) : p.income),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          })
                        : Row(
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
