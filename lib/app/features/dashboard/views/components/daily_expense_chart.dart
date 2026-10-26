import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class DailyExpenseChart extends StatelessWidget {
  const DailyExpenseChart({super.key, required this.values});
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    var max = 1.0;
    for (final v in values) {
      if (v > max) max = v;
    }
    return SizedBox(
      height: 70,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final v in values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Container(
                  height: (v / max * 70).clamp(2.0, 70.0).toDouble(),
                  decoration: BoxDecoration(
                    color: p.expense.withOpacity(.85),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
