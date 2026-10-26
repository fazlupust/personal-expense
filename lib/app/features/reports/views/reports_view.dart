import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_widgets.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/entry_type.dart';
import '../../transactions/controllers/transactions_controller.dart';
import '../../transactions/views/components/entry_form_sheet.dart';
import '../../transactions/views/components/transaction_tile.dart';
import '../controllers/reports_controller.dart';
import 'components/category_bars.dart';
import 'components/six_month_chart.dart';

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return GetBuilder<ReportsController>(
      builder: (rc) => GetBuilder<TransactionsController>(builder: (_) {
        final r = rc.summary();
        final net = r.net;
        return ContentWrap(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageTitle('Reports'),
              SegmentBar<int>(
                options: {
                  1: 'This month'.tr,
                  3: '3 months'.tr,
                  12: '12 months'.tr,
                  0: 'All time'.tr,
                },
                value: rc.range,
                onChanged: rc.setRange,
              ),
              AdaptiveColumns(
                left: [
                  AppCard(
                    child: StatGrid(items: [
                      StatItem('Income', Fmt.money(r.income), color: p.income),
                      StatItem('Expense', Fmt.money(r.expense), color: p.expense),
                      StatItem('Net saved', '${net < 0 ? '−' : ''}${Fmt.money(net.abs())}'),
                      StatItem('Savings rate',
                          r.income > 0 ? '${Fmt.count((net / r.income * 100).round())}%' : '–'),
                      StatItem('Largest expense', r.largest > 0 ? Fmt.money(r.largest) : '–'),
                      StatItem('Entries', Fmt.count(r.count)),
                    ]),
                  ),
                  AppCard(
                    title: 'Income vs expense, last 6 months',
                    child: SixMonthChart(months: r.months),
                  ),
                ],
                right: [
                  AppCard(
                    title: 'Expenses by category',
                    child: CategoryBars(
                      data: r.expenseByCategory,
                      total: r.expense,
                      type: EntryType.expense,
                    ),
                  ),
                  AppCard(
                    title: 'Income by category',
                    child: CategoryBars(
                      data: r.incomeByCategory,
                      total: r.income,
                      type: EntryType.income,
                    ),
                  ),
                  AppCard(title: 'By account', child: _AccountBreakdown(data: r.byAccount)),
                  AppCard(
                    title: 'Biggest expenses',
                    flush: true,
                    child: r.topExpenses.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
                            child: Center(
                              child: Text('No expenses in this period.'.tr,
                                  style: TextStyle(color: p.mute)),
                            ),
                          )
                        : Column(
                            children: [
                              for (var i = 0; i < r.topExpenses.length; i++)
                                TransactionTile(
                                  entry: r.topExpenses[i],
                                  showDivider: i < r.topExpenses.length - 1,
                                  onTap: () => showEntrySheet(context, entry: r.topExpenses[i]),
                                ),
                            ],
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

class _AccountBreakdown extends StatelessWidget {
  const _AccountBreakdown({required this.data});
  final Map<String, List<double>> data;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(child: Text('No data for this period.'.tr, style: TextStyle(color: p.mute))),
      );
    }
    return Column(
      children: [
        for (final e in data.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(e.key.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: p.mute)),
                ),
                Expanded(
                  child: Text(
                    '${'In'.tr} ${Fmt.money(e.value[0])} · ${'Out'.tr} ${Fmt.money(e.value[1])}',
                    style: TextStyle(fontSize: 12, color: p.mute),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${e.value[0] - e.value[1] < 0 ? '−' : ''}${Fmt.money((e.value[0] - e.value[1]).abs())}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: e.value[0] - e.value[1] < 0 ? p.expense : p.income,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
