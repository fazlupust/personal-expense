import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../controllers/reports_controller.dart';

class SixMonthChart extends StatelessWidget {
  const SixMonthChart({super.key, required this.months});
  final List<MonthBar> months;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    var max = 1.0;
    for (final m in months) {
      if (m.income > max) max = m.income;
      if (m.expense > max) max = m.expense;
    }
    return SizedBox(
      height: 130,
      child: Row(
        children: [
          for (final m in months)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _Bar(factor: m.income / max, color: p.income)),
                          const SizedBox(width: 3),
                          Expanded(child: _Bar(factor: m.expense / max, color: p.expense)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(m.label, style: TextStyle(fontSize: 11, color: p.mute)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.factor, required this.color});
  final double factor;
  final Color color;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: factor.clamp(0.02, 1.0).toDouble(),
          widthFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            ),
          ),
        ),
      );
}
