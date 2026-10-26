import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/entry_type.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../categories/controllers/categories_controller.dart';
import '../../controllers/transactions_controller.dart';
import 'entry_form_sheet.dart';

class TransactionTable extends StatelessWidget {
  const TransactionTable({super.key, required this.rows});
  final List<TransactionModel> rows;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final tc = Get.find<TransactionsController>();
    final cats = Get.find<CategoriesController>();
    final net = tc.sum(rows, EntryType.income) - tc.sum(rows, EntryType.expense);
    final bold = TextStyle(fontWeight: FontWeight.w700, color: p.ink);

    return AppCard(
      flush: true,
      child: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: c.maxWidth),
            child: DataTable(
              showCheckboxColumn: false,
              columnSpacing: 20,
              horizontalMargin: 12,
              headingTextStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.mute),
              dataTextStyle: TextStyle(fontSize: 13, color: p.ink),
              columns: [
                DataColumn(label: Text('Date'.tr)),
                DataColumn(label: Text('Note'.tr)),
                DataColumn(label: Text('Category'.tr)),
                DataColumn(label: Text('Account'.tr)),
                DataColumn(label: Text('Amount'.tr), numeric: true),
              ],
              rows: [
                for (final e in rows)
                  DataRow(
                    onSelectChanged: (_) => showEntrySheet(context, entry: e),
                    cells: [
                      DataCell(Text(Fmt.date(e.date, 'd MMM'))),
                      DataCell(Text(e.note.isEmpty ? '–' : e.note)),
                      DataCell(Text('${cats.emojiOf(e.type, e.category)} ${e.category.tr}')),
                      DataCell(Text(e.account.tr)),
                      DataCell(Text(
                        '${e.type == EntryType.income ? '+' : '−'}${Fmt.money(e.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: e.type == EntryType.income ? p.income : p.expense,
                        ),
                      )),
                    ],
                  ),
                DataRow(cells: [
                  DataCell(Text('${'Net'.tr} (${Fmt.count(rows.length)} ${'entries'.tr})', style: bold)),
                  const DataCell(Text('')),
                  const DataCell(Text('')),
                  const DataCell(Text('')),
                  DataCell(Text('${net < 0 ? '−' : ''}${Fmt.money(net.abs())}', style: bold)),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
