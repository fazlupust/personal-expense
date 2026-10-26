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
      return ContentWrap(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageTitle('Transactions'),
            const MonthSwitcher(),
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
            if (rows.isEmpty)
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
          ],
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
