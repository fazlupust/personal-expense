import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/entry_type.dart';
import '../../../data/models/transaction_model.dart';

enum TxFilter { all, income, expense }

class TransactionsController extends GetxController {
  TransactionsController(this._prefs);
  final SharedPreferences _prefs;

  final searchCtrl = TextEditingController();
  List<TransactionModel> entries = [];
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  TxFilter filter = TxFilter.all;
  bool tableMode = false;
  String query = '';

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }

  void _load() {
    final raw = _prefs.getString(AppConstants.prefsEntries);
    if (raw == null) return;
    try {
      entries = (jsonDecode(raw) as List)
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      entries = [];
    }
  }

  Future<void> _persist() => _prefs.setString(
        AppConstants.prefsEntries,
        jsonEncode(entries.map((e) => e.toJson()).toList()),
      );

  static int _newestFirst(TransactionModel a, TransactionModel b) {
    final c = b.date.compareTo(a.date);
    return c != 0 ? c : b.id.compareTo(a.id);
  }

  // ---- queries ----
  List<TransactionModel> get monthRows => entries
      .where((e) => e.date.year == month.year && e.date.month == month.month)
      .toList()
    ..sort(_newestFirst);

  List<TransactionModel> get visibleRows {
    final q = query.trim().toLowerCase();
    return monthRows.where((e) {
      final okType = switch (filter) {
        TxFilter.all => true,
        TxFilter.income => e.type == EntryType.income,
        TxFilter.expense => e.type == EntryType.expense,
      };
      final okQuery = q.isEmpty || '${e.note} ${e.category} ${e.account}'.toLowerCase().contains(q);
      return okType && okQuery;
    }).toList();
  }

  List<TransactionModel> get recent => (entries.toList()..sort(_newestFirst)).take(5).toList();

  double sum(Iterable<TransactionModel> rows, EntryType t) =>
      rows.where((e) => e.type == t).fold(0.0, (a, e) => a + e.amount);

  /// Totals per category, biggest first.
  Map<String, double> group(Iterable<TransactionModel> rows, EntryType t) {
    final m = <String, double>{};
    for (final e in rows) {
      if (e.type == t) m[e.category] = (m[e.category] ?? 0) + e.amount;
    }
    final sorted = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  int get daysInMonth => DateTime(month.year, month.month + 1, 0).day;

  int get elapsedDays {
    final n = DateTime.now();
    return (n.year == month.year && n.month == month.month) ? n.day : daysInMonth;
  }

  List<double> dailyExpense(Iterable<TransactionModel> rows) {
    final d = List<double>.filled(daysInMonth, 0);
    for (final e in rows) {
      if (e.type == EntryType.expense) d[e.date.day - 1] += e.amount;
    }
    return d;
  }

  // ---- actions ----
  void shiftMonth(int delta) {
    month = DateTime(month.year, month.month + delta);
    update();
  }

  void setQuery(String v) {
    query = v;
    update();
  }

  void setFilter(TxFilter f) {
    filter = f;
    update();
  }

  void setTableMode(bool v) {
    tableMode = v;
    update();
  }

  void save(TransactionModel m) {
    final i = entries.indexWhere((e) => e.id == m.id);
    if (i >= 0) {
      entries[i] = m;
    } else {
      entries.add(m);
    }
    month = DateTime(m.date.year, m.date.month);
    _persist();
    update();
  }

  void remove(int id) {
    entries.removeWhere((e) => e.id == id);
    _persist();
    update();
  }
}
