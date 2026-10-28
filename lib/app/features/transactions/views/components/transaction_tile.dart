import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/entry_type.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../categories/controllers/categories_controller.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.entry,
    required this.onTap,
    this.showDivider = true,
    this.isAmountHidden = false,
  });

  final TransactionModel entry;
  final VoidCallback onTap;
  final bool showDivider;
  final bool isAmountHidden;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isIncome = entry.type == EntryType.income;
    final emoji = Get.find<CategoriesController>().emojiOf(entry.type, entry.category);
    final time = entry.createdAt ?? entry.date;
    final timeStr = (time.hour != 0 || time.minute != 0 || entry.createdAt != null)
        ? Fmt.date(time, 'h:mm a')
        : '';
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          border: showDivider ? Border(bottom: BorderSide(color: p.line)) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: p.bg, shape: BoxShape.circle),
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.note.isEmpty ? entry.category.tr : entry.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.ink),
                  ),
                  Text(
                    [
                      entry.category.tr,
                      entry.account.tr,
                      Fmt.date(entry.date, 'd MMM'),
                      if (timeStr.isNotEmpty) timeStr,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13.5, color: p.mute),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isAmountHidden
                  ? '${isIncome ? '+' : '−'}••••••'
                  : '${isIncome ? '+' : '−'}${Fmt.money(entry.amount)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: isAmountHidden ? 1.0 : null,
                color: isIncome ? p.income : p.expense,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
