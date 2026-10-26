import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../controllers/transactions_controller.dart';

class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return GetBuilder<TransactionsController>(
      builder: (tc) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _RoundButton(icon: Icons.chevron_left, onTap: () => tc.shiftMonth(-1)),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => tc.resetToCurrentMonth(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Fmt.date(tc.month, 'MMMM yyyy'),
                      style: TextStyle(fontWeight: FontWeight.w700, color: p.ink, fontSize: 15),
                    ),
                    if (!tc.isCurrentMonth) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: p.income.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Current month'.tr,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: p.income),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _RoundButton(icon: Icons.chevron_right, onTap: () => tc.shiftMonth(1)),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Material(
      color: p.card,
      shape: CircleBorder(side: BorderSide(color: p.line)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 38, height: 38, child: Icon(icon, color: p.ink)),
      ),
    );
  }
}
