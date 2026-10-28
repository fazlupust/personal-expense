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

    final dueRows = rows.where((e) => e.account.trim().toLowerCase() == 'due');
    final dueNet = tc.sum(dueRows, EntryType.income) - tc.sum(dueRows, EntryType.expense);
    final isBn = Get.locale?.languageCode == 'bn';

    return AppCard(
      flush: true,
      child: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: c.maxWidth),
            child: DataTable(
              showCheckboxColumn: false,
              columnSpacing: 16,
              horizontalMargin: 12,
              headingTextStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.mute),
              dataTextStyle: TextStyle(fontSize: 13, color: p.ink),
              columns: [
                DataColumn(label: Text('S.N'.tr)),
                DataColumn(label: Text('Amount'.tr), numeric: true),
                DataColumn(label: Text('Date'.tr)),
                DataColumn(label: Text('Category'.tr)),
                DataColumn(label: Text('Due'.tr), numeric: true),
                DataColumn(label: Text('Note'.tr)),
              ],
              rows: [
                for (var i = 0; i < rows.length; i++) ...[
                  () {
                    final e = rows[i];
                    final isDue = e.account.trim().toLowerCase() == 'due';
                    final sign = e.type == EntryType.income ? '+' : '';
                    final color = e.type == EntryType.income ? p.income : p.expense;
                    final note = e.noteText(isBn).trim();
                    final catName = cats.categoryDisplayName(e.type, e.category, isBn);

                    return DataRow(
                      onSelectChanged: (_) => showEntrySheet(context, entry: e),
                      cells: [
                        DataCell(Text(
                          '${i + 1}',
                          style: TextStyle(fontSize: 12, color: p.mute, fontWeight: FontWeight.w500),
                        )),
                        DataCell(Text(
                          '$sign${Fmt.money(e.amount)}',
                          style: TextStyle(fontWeight: FontWeight.w700, color: color),
                        )),
                        DataCell(Text(Fmt.date(e.date, 'd MMM'))),
                        DataCell(Text('${cats.emojiOf(e.type, e.category)} $catName')),
                        DataCell(Text(
                          !isDue ? '–' : '$sign${Fmt.money(e.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: !isDue ? p.mute : color,
                          ),
                        )),
                        DataCell(
                          note.isNotEmpty
                              ? ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 160),
                                  child: Text(
                                    note,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: p.ink.withOpacity(0.85)),
                                  ),
                                )
                              : Text('–', style: TextStyle(color: p.mute)),
                        ),
                      ],
                    );
                  }(),
                ],
                DataRow(
                  color: WidgetStateProperty.all(p.bg.withOpacity(0.5)),
                  cells: [
                    DataCell(Text('Total'.tr, style: bold)),
                    DataCell(Text(
                      '${net < 0 ? '' : (net > 0 ? '+' : '')}${Fmt.money(net.abs())}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: net < 0 ? p.expense : (net > 0 ? p.income : p.ink),
                      ),
                    )),
                    DataCell(Text(
                      '${Fmt.count(rows.length)}${tc.hasMore ? '/${tc.totalCount}' : ''} ${'entries'.tr}',
                      style: TextStyle(color: p.mute, fontSize: 11, fontWeight: FontWeight.w600),
                    )),
                    const DataCell(Text('')),
                    DataCell(Text(
                      dueNet == 0
                          ? '–'
                          : '${dueNet < 0 ? '' : (dueNet > 0 ? '+' : '')}${Fmt.money(dueNet.abs())}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: dueNet < 0 ? p.expense : (dueNet > 0 ? p.income : p.ink),
                      ),
                    )),
                    const DataCell(Text('')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
