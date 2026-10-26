import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_widgets.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/entry_type.dart';
import '../../../data/services/auth_service.dart';
import '../../reports/views/components/category_bars.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../navigation/controllers/navigation_controller.dart';
import '../../transactions/controllers/transactions_controller.dart';
import '../../transactions/views/components/entry_form_sheet.dart';
import '../../transactions/views/components/month_switcher.dart';
import '../../transactions/views/components/transaction_tile.dart';
import 'components/balance_card.dart';
import 'components/dashboard_stats_card.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  Widget _buildGreetingBar(BuildContext context, SettingsController s) {
    final p = context.pal;
    final auth = Get.isRegistered<AuthService>() ? AuthService.to : null;
    final user = auth?.userProfile.value;
    final isBn = Get.locale?.languageCode == 'bn';
    final userDisplayName = user?.displayName(isBn) ?? '';
    final displayName = userDisplayName.isNotEmpty
        ? userDisplayName
        : (s.name.isNotEmpty ? s.name : 'Personal Expense User'.tr);
    final initial = displayName.isNotEmpty ? displayName.characters.first.toUpperCase() : '?';

    final h = DateTime.now().hour;
    final greetingText = h < 12
        ? 'Good morning'.tr
        : (h < 18 ? 'Good afternoon'.tr : 'Good evening'.tr);
    final icon = h < 12
        ? Icons.wb_sunny_rounded
        : (h < 18 ? Icons.wb_twilight_rounded : Icons.nightlight_round);
    final iconColor = h < 18 ? const Color(0xFFF39C12) : const Color(0xFF9B59B6);

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        children: [
          // Avatar with subtle primary outline
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [p.income, const Color(0xFF134E35)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: p.income.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 14, color: iconColor),
                    const SizedBox(width: 4),
                    Text(
                      greetingText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: p.mute,
                      ),
                    ),
                    if (user?.userNo != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: p.income.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${user!.userNo}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: p.income,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                  ),
                ),
              ],
            ),
          ),
          // Shortcut to Profile / Settings
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Get.find<NavigationController>().select(3),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.line),
              ),
              child: Icon(Icons.person_outline_rounded, size: 20, color: p.ink),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return GetBuilder<SettingsController>(
      builder: (s) => GetBuilder<TransactionsController>(builder: (tc) {
        final rows = tc.monthRows;
        final income = tc.sum(rows, EntryType.income);
        final expense = tc.sum(rows, EntryType.expense);
        final byCat = tc.group(rows, EntryType.expense);
        final recent = tc.recent;

        return ContentWrap(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGreetingBar(context, s),
              const SizedBox(height: 4),
              const MonthSwitcher(),
              AdaptiveColumns(
                left: [
                  BalanceCard(income: income, expense: expense, budget: s.budget),
                  DashboardStatsCard(
                    controller: tc,
                    income: income,
                    expense: expense,
                    byCategory: byCat,
                    entryCount: rows.length,
                    daily: tc.dailyExpense(rows),
                  ),
                ],
                right: [
                  AppCard(
                    title: 'Recent transactions',
                    action: 'See all',
                    onAction: () => Get.find<NavigationController>().select(1),
                    flush: true,
                    child: recent.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            child: Center(
                              child: Text(
                                'No transactions yet. Tap “+ Add”.'.tr,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: p.mute),
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              for (var i = 0; i < recent.length; i++)
                                TransactionTile(
                                  entry: recent[i],
                                  showDivider: i < recent.length - 1,
                                  onTap: () => showEntrySheet(context, entry: recent[i]),
                                ),
                            ],
                          ),
                  ),
                  AppCard(
                    title: 'Expenses by category',
                    child: CategoryBars(data: byCat, total: expense, type: EntryType.expense),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}
