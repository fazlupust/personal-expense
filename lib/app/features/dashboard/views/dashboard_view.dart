import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_widgets.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/entry_type.dart';
import '../../../data/services/auth_service.dart';
import '../../reports/views/components/category_bars.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../settings/views/components/budget_management_sheet.dart';
import '../../navigation/controllers/navigation_controller.dart';
import '../../transactions/controllers/transactions_controller.dart';
import '../../transactions/views/components/entry_form_sheet.dart';
import '../../transactions/views/components/transaction_tile.dart';
import 'components/balance_card.dart';
import 'components/dashboard_prayer_card.dart';
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

    final now = DateTime.now();
    final h = now.hour;
    final greetingText = h < 12
        ? 'Good morning'.tr
        : (h < 18 ? 'Good afternoon'.tr : 'Good evening'.tr);
    final icon = h < 12
        ? Icons.wb_sunny_rounded
        : (h < 18 ? Icons.wb_twilight_rounded : Icons.nightlight_round);
    final iconColor = h < 18 ? const Color(0xFFF39C12) : const Color(0xFF9B59B6);

    final dateFormatted = Fmt.date(now, 'EEE, d MMM yyyy');
    final timeFormatted = Fmt.date(now, 'h:mm a');

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
                    Icon(icon, size: 16, color: iconColor),
                    const SizedBox(width: 5),
                    Text(
                      greetingText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: p.mute,
                      ),
                    ),
                    Text(
                      ' · ',
                      style: TextStyle(
                        fontSize: 13,
                        color: p.mute.withOpacity(0.5),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        '$dateFormatted, $timeFormatted',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: p.mute.withOpacity(0.85),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
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

  Widget _buildBudgetAlertBanner(
    BuildContext context, {
    required AppPalette p,
    required bool totalExceeded,
    required double totalOver,
    required Map<String, double> exceededCategories,
    bool isExpenseHidden = false,
  }) {
    final catCount = exceededCategories.length;
    final catNames = exceededCategories.keys.map((k) => k.tr).toList();

    String title = 'Budget Limit Exceeded!'.tr;
    String subtitle = '';

    if (totalExceeded && catCount > 0) {
      subtitle =
          '${'Total monthly budget'.tr} & $catCount ${catCount == 1 ? '1 category budget exceeded'.tr : 'categories budget exceeded'.tr}';
    } else if (totalExceeded) {
      final overText = isExpenseHidden ? '••••••' : '${AppConstants.currency}${Fmt.money(totalOver)}';
      subtitle = '${'Total monthly budget exceeded by'.tr} $overText';
    } else {
      final namesStr = catNames.take(2).join(', ') + (catNames.length > 2 ? ' +${catNames.length - 2}' : '');
      subtitle = '$namesStr ${'budget exceeded'.tr}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: p.expense.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.expense.withOpacity(0.4), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => showBudgetManagementSheet(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: p.expense.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning_amber_rounded, color: p.expense, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: p.expense,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: p.ink.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: p.expense,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'View / Manage'.tr,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return GetBuilder<SettingsController>(
      builder: (s) => GetBuilder<TransactionsController>(builder: (tc) {
        // Dashboard strictly shows current month's data only
        final rows = tc.currentMonthRows;
        final income = tc.sum(rows, EntryType.income);
        final expense = tc.sum(rows, EntryType.expense);
        final byCat = tc.group(rows, EntryType.expense);
        final recent = tc.recent;

        // Calculate exceeded budgets
        final totalBudgetExceeded = s.budget > 0 && expense > s.budget;
        final exceededCategories = <String, double>{};
        for (final entry in byCat.entries) {
          final catBudget = s.getCategoryBudget(entry.key);
          if (catBudget > 0 && entry.value > catBudget) {
            exceededCategories[entry.key] = entry.value - catBudget;
          }
        }
        final hasBudgetAlert = totalBudgetExceeded || exceededCategories.isNotEmpty;

        return ContentWrap(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGreetingBar(context, s),
              const SizedBox(height: 6),
              if (hasBudgetAlert)
                _buildBudgetAlertBanner(
                  context,
                  p: p,
                  totalExceeded: totalBudgetExceeded,
                  totalOver: expense - s.budget,
                  exceededCategories: exceededCategories,
                  isExpenseHidden: s.isExpenseHidden,
                ),
              if (s.showPrayerCard) const DashboardPrayerCard(),
              AdaptiveColumns(
                left: [
                  BalanceCard(
                    income: income,
                    expense: expense,
                    budget: s.budget,
                    isHidden: s.isIncomeHidden || s.isExpenseHidden,
                    onToggleVisibility: s.toggleBalanceVisibility,
                    isIncomeHidden: s.isIncomeHidden,
                    onToggleIncomeVisibility: s.toggleIncomeVisibility,
                    isExpenseHidden: s.isExpenseHidden,
                    onToggleExpenseVisibility: s.toggleExpenseVisibility,
                  ),
                  DashboardStatsCard(
                    controller: tc,
                    income: income,
                    expense: expense,
                    byCategory: byCat,
                    entryCount: rows.length,
                    daily: tc.dailyExpense(rows),
                    isHidden: s.isIncomeHidden,
                    isExpenseHidden: s.isExpenseHidden,
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
                                  isAmountHidden: recent[i].type == EntryType.income
                                      ? s.isIncomeHidden
                                      : s.isExpenseHidden,
                                  onTap: () => showEntrySheet(context, entry: recent[i]),
                                ),
                            ],
                          ),
                  ),
                  AppCard(
                    title: 'Expenses by category',
                    child: CategoryBars(
                      data: byCat,
                      total: expense,
                      type: EntryType.expense,
                      isHidden: s.isExpenseHidden,
                    ),
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
