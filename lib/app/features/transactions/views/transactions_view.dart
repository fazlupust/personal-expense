import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_widgets.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/entry_type.dart';
import '../../../data/models/transaction_model.dart';
import '../controllers/transactions_controller.dart';
import 'components/entry_form_sheet.dart';
import 'components/month_switcher.dart';
import 'components/transaction_table.dart';
import 'components/transaction_tile.dart';

class TransactionsView extends StatelessWidget {
  const TransactionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return GetBuilder<TransactionsController>(builder: (tc) {
      final rows = tc.visibleRows;
      return RefreshIndicator(
        onRefresh: tc.refreshTransactions,
        color: p.income,
        child: ContentWrap(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (tc.unsyncedCount > 0) ...[
                Builder(builder: (context) {
                  final isBn = Get.locale?.languageCode == 'bn';
                  final lastErr = tc.unsyncedEntries.firstWhereOrNull((e) => e.syncError != null)?.syncError;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF97316).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_off_rounded, color: Color(0xFFEA580C), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isBn
                                    ? '${Fmt.count(tc.unsyncedCount)}টি লেনদেন ক্লাউডে সিঙ্ক হয়নি (অফলাইন)'
                                    : '${tc.unsyncedCount} entries not synced to cloud (offline)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF9A3412),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                lastErr != null
                                    ? (isBn ? 'কারণ: $lastErr' : 'Reason: $lastErr')
                                    : (isBn
                                        ? 'লগআউট বা ফোন ক্লিন করার আগে সিঙ্ক করে নিন'
                                        : 'Sync before logging out or cleaning phone'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFFC2410C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: tc.isSyncingPending ? null : tc.syncPendingTransactions,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA580C),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: tc.isSyncingPending
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isBn ? 'সিঙ্ক করুন' : 'Sync Now',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const MonthSwitcher(),
              if (tc.entries.length > rows.length &&
                  tc.latestActiveMonth != null &&
                  (tc.latestActiveMonth!.month != tc.month.month ||
                      tc.latestActiveMonth!.year != tc.month.year)) ...[
                Builder(builder: (context) {
                  final isBn = Get.locale?.languageCode == 'bn';
                  final lastMonthName = Fmt.date(tc.latestActiveMonth!, 'MMMM yyyy');
                  final prevCount = tc.entries
                      .where((e) =>
                          e.date.year == tc.latestActiveMonth!.year &&
                          e.date.month == tc.latestActiveMonth!.month)
                      .length;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: p.income.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.income.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.history_rounded, color: p.income, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isBn
                                ? '$lastMonthName-এ আপনার $prevCountটি লেনদেন রয়েছে।'
                                : 'You have $prevCount entries in $lastMonthName.',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: p.ink,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            tc.setYearAndMonth(
                                tc.latestActiveMonth!.year, tc.latestActiveMonth!.month);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: p.income,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isBn ? 'দেখুন' : 'View',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              TextField(
                controller: tc.searchCtrl,
                onChanged: tc.setQuery,
                decoration: InputDecoration(
                  hintText: 'Search notes, categories, accounts'.tr,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 10),
              SegmentBar<TxFilter>(
                options: {
                  TxFilter.all: 'All'.tr,
                  TxFilter.income: 'Income'.tr,
                  TxFilter.expense: 'Expenses'.tr,
                },
                value: tc.filter,
                onChanged: tc.setFilter,
              ),
              SegmentBar<bool>(
                options: {false: 'List view'.tr, true: 'Table view'.tr},
                value: tc.tableMode,
                onChanged: tc.setTableMode,
              ),
              if (tc.isLoading && rows.isEmpty)
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: p.income),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Loading transactions...'.tr,
                            style: TextStyle(color: p.mute, fontSize: 13.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (rows.isEmpty)
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      'Nothing here. Tap “+ Add” to record income or an expense.'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.mute),
                    ),
                  ),
                )
            else if (tc.tableMode)
              TransactionTable(rows: rows)
            else
              ..._groupedList(context, tc, rows),
            if (rows.isNotEmpty) ...[
              if (tc.hasMore) ...[
                const SizedBox(height: 16),
                Center(
                  child: InkWell(
                    onTap: tc.loadMore,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      decoration: BoxDecoration(
                        color: p.income.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: p.income.withOpacity(0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.expand_circle_down_outlined, size: 20, color: p.income),
                          const SizedBox(width: 8),
                          Text(
                            '${'Load More'.tr} (${tc.remainingCount} ${'more'.tr})',
                            style: TextStyle(
                              color: p.income,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${'Showing'.tr} ${tc.loadedCount} ${'of'.tr} ${tc.totalCount} ${'entries'.tr}',
                    style: TextStyle(fontSize: 12, color: p.mute),
                  ),
                ),
              ] else if (tc.totalCount > 40) ...[
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    '${'Showing'.tr} ${tc.totalCount} ${'of'.tr} ${tc.totalCount} ${'entries'.tr}',
                    style: TextStyle(fontSize: 12, color: p.mute),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  });
}

  List<Widget> _groupedList(BuildContext context, TransactionsController tc, List<TransactionModel> rows) {
    final p = context.pal;
    final days = <DateTime, List<TransactionModel>>{};
    for (final e in rows) {
      days.putIfAbsent(e.date, () => []).add(e);
    }
    final out = <Widget>[];
    days.forEach((day, list) {
      final net = tc.sum(list, EntryType.income) - tc.sum(list, EntryType.expense);
      out.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(Fmt.date(day, 'EEE, d MMM'), style: TextStyle(fontSize: 12, color: p.mute)),
            Text('${net < 0 ? '−' : '+'}${Fmt.money(net.abs())}',
                style: TextStyle(fontSize: 12, color: p.mute)),
          ],
        ),
      ));
      out.add(AppCard(
        flush: true,
        child: Column(
          children: [
            for (var i = 0; i < list.length; i++)
              TransactionTile(
                entry: list[i],
                showDivider: i < list.length - 1,
                onTap: () => showEntrySheet(context, entry: list[i]),
              ),
          ],
        ),
      ));
    });
    return out;
  }
}
