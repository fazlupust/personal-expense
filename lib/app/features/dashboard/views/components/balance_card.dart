import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.income, required this.expense, required this.budget});
  final double income;
  final double expense;
  final double budget;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final fg = p.onAcc;
    final over = budget > 0 && expense > budget;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: p.acc, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Balance this month'.tr, style: TextStyle(color: fg.withOpacity(.7), fontSize: 13)),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 14),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                Fmt.money(income - expense),
                style: TextStyle(color: fg, fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -.5),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: _AmountBox(label: 'Income', value: income, fg: fg)),
              const SizedBox(width: 10),
              Expanded(child: _AmountBox(label: 'Expense', value: expense, fg: fg)),
            ],
          ),
          if (budget > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (expense / budget).clamp(0.0, 1.0).toDouble(),
                minHeight: 8,
                backgroundColor: Colors.grey.withOpacity(.35),
                valueColor: AlwaysStoppedAnimation(over ? p.expense : p.income),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              over
                  ? '${'Over budget by'.tr} ${Fmt.money(expense - budget)}'
                  : '${Fmt.money(budget - expense)} ${'left of'.tr} ${Fmt.money(budget)}',
              style: TextStyle(color: fg.withOpacity(.8), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _AmountBox extends StatelessWidget {
  const _AmountBox({required this.label, required this.value, required this.fg});
  final String label;
  final double value;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(.25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.tr, style: TextStyle(fontSize: 12, color: fg)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(Fmt.money(value),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: fg)),
            ),
          ],
        ),
      );
}
