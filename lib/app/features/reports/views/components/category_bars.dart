import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/entry_type.dart';
import '../../../categories/controllers/categories_controller.dart';

/// Horizontal bars: category label, proportion bar, amount and percentage.
class CategoryBars extends StatelessWidget {
  const CategoryBars({
    super.key,
    required this.data,
    required this.total,
    required this.type,
    this.isHidden = false,
    this.onTapCategory,
  });
  final Map<String, double> data;
  final double total;
  final EntryType type;
  final bool isHidden;
  final ValueChanged<String>? onTapCategory;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Text('No data for this period.'.tr, style: TextStyle(color: p.mute, fontSize: 14.5)),
        ),
      );
    }
    final cats = Get.find<CategoriesController>();
    final color = type == EntryType.income ? p.income : p.expense;
    return Column(
      children: [
        for (final e in data.entries)
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTapCategory != null ? () => onTapCategory!(e.key) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              child: Row(
                children: [
                  Flexible(
                    flex: 4,
                    child: Text(
                      '${cats.emojiOf(type, e.key)} ${e.key.tr}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: p.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: total > 0 ? (e.value / total).clamp(0.0, 1.0).toDouble() : 0,
                        minHeight: 10,
                        backgroundColor: p.line,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 4,
                    child: Text(
                      '${isHidden ? '••••••' : Fmt.money(e.value)} · ${Fmt.count(total > 0 ? (e.value / total * 100).round() : 0)}%',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: isHidden ? 1.0 : null,
                        color: p.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
