import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/entry_type.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/transaction_service.dart';

enum TxFilter { all, income, expense }

class TransactionsController extends GetxController {
  TransactionsController();

  final searchCtrl = TextEditingController();
  List<TransactionModel> entries = [];
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  TxFilter filter = TxFilter.all;
  bool tableMode = false;
  String query = '';

  StreamSubscription<List<TransactionModel>>? _sub;

  bool get isCurrentMonth {
    final now = DateTime.now();
    return month.year == now.year && month.month == now.month;
  }

  static const int pageSize = 40;
  int currentLimit = 40;

  void resetLimit() {
    currentLimit = pageSize;
  }

  void loadMore() {
    currentLimit += pageSize;
    update();
  }

  void resetToCurrentMonth() {
    final now = DateTime.now();
    final cur = DateTime(now.year, now.month);
    currentLimit = pageSize;
    if (month.year != cur.year || month.month != cur.month) {
      month = cur;
      update();
    }
  }

  @override
  void onInit() {
    super.onInit();
    resetToCurrentMonth();
    _initTransactions();
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    _sub?.cancel();
    super.onClose();
  }

  void _initTransactions() {
    if (Get.isRegistered<TransactionService>() && Get.isRegistered<AuthService>()) {
      final auth = Get.find<AuthService>();
      final txService = Get.find<TransactionService>();

      ever(auth.firebaseUser, (user) {
        _sub?.cancel();
        if (user != null) {
          _sub = txService.streamUserTransactions(user.uid).listen((list) {
            entries = list;
            update();
          });
        } else {
          entries = [];
          update();
        }
      });

      if (auth.currentUid != null) {
        _sub = txService.streamUserTransactions(auth.currentUid!).listen((list) {
          entries = list;
          update();
        });
      }
    }
  }

  bool isYearOnly = false;

  void setYearAndMonth(int y, int m) {
    month = DateTime(y, m);
    isYearOnly = false;
    currentLimit = pageSize;
    update();
  }

  void setYearOnly(int y) {
    month = DateTime(y, 1);
    isYearOnly = true;
    currentLimit = pageSize;
    update();
  }

  List<TransactionModel> get currentMonthRows {
    final now = DateTime.now();
    return entries
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList()
      ..sort(_newestFirst);
  }

  static int _newestFirst(TransactionModel a, TransactionModel b) {
    final c = b.date.compareTo(a.date);
    return c != 0 ? c : b.id.compareTo(a.id);
  }

  // ---- queries ----
  List<TransactionModel> get monthRows {
    if (isYearOnly) {
      return entries
          .where((e) => e.date.year == month.year)
          .toList()
        ..sort(_newestFirst);
    }
    return entries
        .where((e) => e.date.year == month.year && e.date.month == month.month)
        .toList()
      ..sort(_newestFirst);
  }

  List<TransactionModel> get allVisibleRows {
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

  List<TransactionModel> get visibleRows => allVisibleRows.take(currentLimit).toList();

  bool get hasMore => allVisibleRows.length > currentLimit;
  int get totalCount => allVisibleRows.length;
  int get loadedCount => visibleRows.length;
  int get remainingCount => (allVisibleRows.length - currentLimit).clamp(0, allVisibleRows.length);

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
    currentLimit = pageSize;
    update();
  }

  void setQuery(String v) {
    query = v;
    currentLimit = pageSize;
    update();
  }

  void setFilter(TxFilter f) {
    filter = f;
    currentLimit = pageSize;
    update();
  }

  void setTableMode(bool v) {
    tableMode = v;
    update();
  }

  Future<void> save(TransactionModel m) async {
    if (Get.isRegistered<TransactionService>()) {
      final txService = Get.find<TransactionService>();
      final exists = entries.any((e) => e.id == m.id);
      if (exists) {
        await txService.updateTransaction(m);
      } else {
        await txService.addTransaction(
          categoryId: m.categoryId,
          categoryNameBn: m.categoryNameBn,
          categoryNameEn: m.categoryNameEn,
          type: m.type,
          amount: m.amount,
          noteBn: m.noteBn,
          noteEn: m.noteEn,
          date: m.date,
          account: m.account,
          latitude: m.latitude,
          longitude: m.longitude,
          deviceInfo: m.deviceInfo,
        );
      }
    } else {
      final i = entries.indexWhere((e) => e.id == m.id);
      if (i >= 0) {
        entries[i] = m;
      } else {
        entries.add(m);
      }
      month = DateTime(m.date.year, m.date.month);
      update();
    }
  }

  Future<void> remove(String id) async {
    // 1. Immediately remove from local list for instant UI response
    entries.removeWhere((e) => e.id == id);
    update();

    // 2. Perform reliable cloud delete
    if (Get.isRegistered<TransactionService>()) {
      try {
        await Get.find<TransactionService>().deleteTransaction(id);
      } catch (e) {
        debugPrint('[TransactionsController] remove cloud error: $e');
      }
    }

    if (Get.context != null) {
      Get.snackbar(
        'Success'.tr,
        'Transaction deleted'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0D9488),
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 24),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 12,
      );
    }
  }
}
