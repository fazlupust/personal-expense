import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_widgets.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../data/models/entry_type.dart';
import '../../transactions/controllers/transactions_controller.dart';
import '../../transactions/views/components/entry_form_sheet.dart';
import '../../transactions/views/components/transaction_tile.dart';
import 'components/category_bars.dart';

/// Full-page report summary for the selected month or year.
class GenerateReportView extends StatelessWidget {
  const GenerateReportView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Generated Report'.tr,
        showBackButton: true,
      ),
      body: SafeArea(
        child: GetBuilder<TransactionsController>(
          builder: (tc) {
            final rows = tc.monthRows;
            final income = tc.sum(rows, EntryType.income);
            final expense = tc.sum(rows, EntryType.expense);
            final net = income - expense;
            final byExpenseCat = tc.group(rows, EntryType.expense);
            final byIncomeCat = tc.group(rows, EntryType.income);

            final periodTitle = tc.isYearOnly
                ? '${'All Year'.tr} ${tc.month.year}'
                : Fmt.date(tc.month, 'MMMM yyyy');

            final daysInMonth = DateUtils.getDaysInMonth(tc.month.year, tc.month.month);
            final avgPerDay = expense / (tc.isYearOnly ? 365 : daysInMonth);
            final savingsRate = income > 0 ? ((income - expense) / income * 100).round() : 0;

            final largestExpense = rows
                .where((e) => e.type == EntryType.expense)
                .fold<double>(0.0, (m, e) => e.amount > m ? e.amount : m);

            // Group by account
            final byAccount = <String, double>{};
            for (final r in rows) {
              byAccount[r.account] = (byAccount[r.account] ?? 0) + r.amount;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: ContentWrap(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Period Header Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0F4730),
                            const Color(0xFF1E6B4A),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F4730).withOpacity(0.30),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_month_rounded,
                                      size: 14,
                                      color: Colors.white.withOpacity(0.95),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Report Period'.tr,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withOpacity(0.95),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (net >= 0 ? const Color(0xFF4EFA9D) : const Color(0xFFFF9488)).withOpacity(0.20),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: (net >= 0 ? const Color(0xFF4EFA9D) : const Color(0xFFFF9488)).withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  net >= 0 ? 'Surplus'.tr : 'Deficit'.tr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: net >= 0 ? const Color(0xFF5DFFB2) : const Color(0xFFFF9488),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            periodTitle,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${Fmt.count(rows.length)} ${'entries'.tr} · ${'Turnover'.tr}: ${Fmt.money(income + expense)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. Financial Highlight Metric Cards
                    Row(
                      children: [
                        Expanded(
                          child: _ReportMetricTile(
                            label: 'Total income'.tr,
                            amount: income,
                            color: p.income,
                            icon: Icons.arrow_downward_rounded,
                            subtitle: '${rows.where((e) => e.type == EntryType.income).length} ${'entries'.tr}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ReportMetricTile(
                            label: 'Total expense'.tr,
                            amount: expense,
                            color: p.expense,
                            icon: Icons.arrow_upward_rounded,
                            subtitle: '${rows.where((e) => e.type == EntryType.expense).length} ${'entries'.tr}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 3. Net Savings Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: p.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: p.line),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Net Saved'.tr,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: p.mute,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${net < 0 ? '−' : ''}${Fmt.money(net.abs())}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: net >= 0 ? p.income : p.expense,
                                ),
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _ReportBadge(
                                label: 'Savings rate'.tr,
                                value: income > 0 ? '$savingsRate%' : '–',
                                color: p.income,
                              ),
                              _ReportBadge(
                                label: 'Daily average'.tr,
                                value: Fmt.money(avgPerDay),
                                color: p.acc,
                              ),
                              if (largestExpense > 0)
                                _ReportBadge(
                                  label: 'Largest expense'.tr,
                                  value: Fmt.money(largestExpense),
                                  color: p.expense,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4. Adaptive Columns for Details
                    AdaptiveColumns(
                      left: [
                        // Category Breakdown (Expenses)
                        AppCard(
                          title: 'Expenses by category',
                          child: CategoryBars(
                            data: byExpenseCat,
                            total: expense,
                            type: EntryType.expense,
                          ),
                        ),

                        // Category Breakdown (Income)
                        if (byIncomeCat.isNotEmpty)
                          AppCard(
                            title: 'Income by category',
                            child: CategoryBars(
                              data: byIncomeCat,
                              total: income,
                              type: EntryType.income,
                            ),
                          ),

                        // Account Breakdown
                        if (byAccount.isNotEmpty)
                          AppCard(
                            title: 'By account',
                            child: Column(
                              children: [
                                for (final a in byAccount.entries)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(a.key.tr, style: TextStyle(fontSize: 14, color: p.ink)),
                                        Text(
                                          Fmt.money(a.value),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: p.ink,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                      right: [
                        // Transactions List in this period
                        AppCard(
                          title: 'Transactions in this period',
                          flush: true,
                          child: rows.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Center(
                                    child: Text(
                                      'No transactions for this period.'.tr,
                                      style: TextStyle(color: p.mute, fontSize: 14),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    for (var i = 0; i < rows.length; i++)
                                      TransactionTile(
                                        entry: rows[i],
                                        showDivider: i < rows.length - 1,
                                        onTap: () => showEntrySheet(context, entry: rows[i]),
                                      ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReportMetricTile extends StatelessWidget {
  const _ReportMetricTile({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.subtitle,
  });

  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.mute)),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, size: 16, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              Fmt.money(amount),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: p.mute),
          ),
        ],
      ),
    );
  }
}

class _ReportBadge extends StatelessWidget {
  const _ReportBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: p.mute, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
