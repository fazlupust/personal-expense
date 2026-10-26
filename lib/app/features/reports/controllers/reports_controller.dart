import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/entry_type.dart';
import '../../../data/models/transaction_model.dart';
import '../../transactions/controllers/transactions_controller.dart';

class MonthBar {
  const MonthBar(this.label, this.income, this.expense);
  final String label;
  final double income;
  final double expense;
}

class ReportSummary {
  const ReportSummary({
    required this.income,
    required this.expense,
    required this.count,
    required this.largest,
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.byAccount,
    required this.months,
    required this.topExpenses,
  });

  final double income;
  final double expense;
  final int count;
  final double largest;
  final Map<String, double> expenseByCategory;
  final Map<String, double> incomeByCategory;
  final Map<String, List<double>> byAccount; // [in, out]
  final List<MonthBar> months;
  final List<TransactionModel> topExpenses;

  double get net => income - expense;
}

class ReportsController extends GetxController {
  /// 1 = this month, 3, 12, 0 = all time.
  int range = 1;

  void setRange(int r) {
    range = r;
    update();
  }

  ReportSummary summary() {
    final tc = Get.find<TransactionsController>();
    final now = DateTime.now();
    final from = range > 0 ? DateTime(now.year, now.month - range + 1) : null;
    final rows = tc.entries
        .where((e) => from == null || !DateTime(e.date.year, e.date.month).isBefore(from))
        .toList();

    final expenses = rows.where((e) => e.type == EntryType.expense).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final accounts = <String, List<double>>{};
    for (final e in rows) {
      final a = accounts.putIfAbsent(e.account, () => <double>[0, 0]);
      a[e.type == EntryType.income ? 0 : 1] += e.amount;
    }

    final months = <MonthBar>[
      for (var i = 5; i >= 0; i--) _monthBar(tc, DateTime(now.year, now.month - i)),
    ];

    return ReportSummary(
      income: tc.sum(rows, EntryType.income),
      expense: tc.sum(rows, EntryType.expense),
      count: rows.length,
      largest: expenses.isEmpty ? 0 : expenses.first.amount,
      expenseByCategory: tc.group(rows, EntryType.expense),
      incomeByCategory: tc.group(rows, EntryType.income),
      byAccount: accounts,
      months: months,
      topExpenses: expenses.take(5).toList(),
    );
  }

  MonthBar _monthBar(TransactionsController tc, DateTime d) {
    final r = tc.entries.where((e) => e.date.year == d.year && e.date.month == d.month);
    return MonthBar(Fmt.date(d, 'MMM'), tc.sum(r, EntryType.income), tc.sum(r, EntryType.expense));
  }
}
