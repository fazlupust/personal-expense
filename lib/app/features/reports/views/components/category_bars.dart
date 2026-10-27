import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/entry_type.dart';
import '../../../categories/controllers/categories_controller.dart';

/// Horizontal bars: category label, proportion bar, amount and percentage.
class CategoryBars extends StatelessWidget {
  const CategoryBars({super.key, required this.data, required this.total, required this.type});
  final Map<String, double> data;
  final double total;
  final EntryType type;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Text('No data for this period.'.tr, style: TextStyle(color: p.mute, fontSize: 14)),
        ),
      );
    }
    final cats = Get.find<CategoriesController>();
    final color = type == EntryType.income ? p.income : p.expense;
    return Column(
      children: [
        for (final e in data.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Flexible(
                  flex: 3,
                  child: Text(
                    '${cats.emojiOf(type, e.key)} ${e.key.tr}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: p.mute),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total > 0 ? (e.value / total).clamp(0.0, 1.0).toDouble() : 0,
                      minHeight: 8,
                      backgroundColor: p.line,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 3,
                  child: Text(
                    '${Fmt.money(e.value)} · ${Fmt.count(total > 0 ? (e.value / total * 100).round() : 0)}%',
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.ink),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
