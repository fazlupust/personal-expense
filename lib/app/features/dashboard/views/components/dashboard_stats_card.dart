import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_widgets.dart';
import '../../../../core/utils/formatters.dart';
import '../../../transactions/controllers/transactions_controller.dart';
import 'daily_expense_chart.dart';

class DashboardStatsCard extends StatelessWidget {
  const DashboardStatsCard({
    super.key,
    required this.controller,
    required this.income,
    required this.expense,
    required this.byCategory,
    required this.entryCount,
    required this.daily,
  });

  final TransactionsController controller;
  final double income;
  final double expense;
  final Map<String, double> byCategory;
  final int entryCount;
  final List<double> daily;

  @override
  Widget build(BuildContext context) {
    final rate = income > 0 ? '${Fmt.count(((income - expense) / income * 100).round())}%' : '–';
    final top = byCategory.isEmpty ? '–' : byCategory.keys.first.tr;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatGrid(items: [
            StatItem('Savings rate', rate),
            StatItem('Avg expense per day', Fmt.money(expense / controller.elapsedDays)),
            StatItem('Top category', top),
            StatItem('Entries', Fmt.count(entryCount)),
          ]),
          const SizedBox(height: 10),
          DailyExpenseChart(values: daily),
        ],
      ),
    );
  }
}
