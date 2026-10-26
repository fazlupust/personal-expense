import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_widgets.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/entry_type.dart';
import '../../reports/views/components/category_bars.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../shell/controllers/shell_controller.dart';
import '../../transactions/controllers/transactions_controller.dart';
import '../../transactions/views/components/entry_form_sheet.dart';
import '../../transactions/views/components/month_switcher.dart';
import '../../transactions/views/components/transaction_tile.dart';
import 'components/balance_card.dart';
import 'components/dashboard_stats_card.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  String _greeting(String name) {
    final h = DateTime.now().hour;
    final g = h < 12 ? 'Good morning' : (h < 18 ? 'Good afternoon' : 'Good evening');
    return name.isEmpty ? g.tr : '${g.tr}, $name';
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
              PageTitle(_greeting(s.name)),
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
                    onAction: () => Get.find<ShellController>().select(1),
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
