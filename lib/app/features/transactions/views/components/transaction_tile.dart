import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/entry_type.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../categories/controllers/categories_controller.dart';
import '../../controllers/transactions_controller.dart';

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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.note.isEmpty ? entry.category.tr : entry.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.ink),
                        ),
                      ),
                      if (!entry.isSynced) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _showOfflineReasonSheet(context, entry, p),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFF97316), width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.cloud_off_rounded, size: 11, color: Color(0xFFEA580C)),
                                const SizedBox(width: 3),
                                Text(
                                  Get.locale?.languageCode == 'bn' ? 'অফলাইন' : 'Offline',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFEA580C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
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
                  ? '${isIncome ? '+' : ''}••••••'
                  : '${isIncome ? '+' : ''}${Fmt.money(entry.amount)}',
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

  void _showOfflineReasonSheet(BuildContext context, TransactionModel tx, AppPalette p) {
    final isBn = Get.locale?.languageCode == 'bn';
    final reason = tx.syncError ?? (isBn
        ? 'ইন্টারনেট সমস্যা বা সার্ভার রেসপন্স টাইমআউট হওয়ার কারণে ডাটাটি এখনও ক্লাউডে সিঙ্ক হয়নি।'
        : 'Data not synced yet due to network disconnection or server timeout.');

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: p.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF97316).withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.cloud_off_rounded, color: Color(0xFFEA580C), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBn ? 'অফলাইন সিঙ্ক স্ট্যাটাস' : 'Offline Sync Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: p.ink,
                          ),
                        ),
                        Text(
                          '${tx.category.tr} · ${Fmt.money(tx.amount)} ৳',
                          style: TextStyle(fontSize: 12.5, color: p.mute),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn ? 'সিঙ্ক না হওয়ার আসল কারণ:' : 'Exact Reason Not Synced:',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reason,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: p.ink,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isBn
                    ? '💡 এই লেনদেনটি আপনার ফোনের লোকাল মেমোরিতে নিরাপদে সেভ আছে। ইন্টারনেট চালু হলে স্বয়ংক্রিয়ভাবে ক্লাউডে যাবে। অ্যাপ ক্লিন বা লগআউট করবেন না।'
                    : '💡 This transaction is securely saved in phone local storage. It will sync automatically once internet is connected. Do not clean app data or log out.',
                style: TextStyle(fontSize: 11.5, color: p.mute, height: 1.3),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (Get.isRegistered<TransactionsController>()) {
                    Get.find<TransactionsController>().syncPendingTransactions();
                  }
                },
                icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18),
                label: Text(
                  isBn ? 'এখনই সিঙ্ক করার চেষ্টা করুন' : 'Retry Sync Now',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F8A5B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
