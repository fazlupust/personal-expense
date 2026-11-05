import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/entry_type.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/transaction_service.dart';

enum TxFilter { all, income, expense }

class TransactionsController extends GetxController {
  TransactionsController();

  final searchCtrl = TextEditingController();
  List<TransactionModel> entries = [];
  bool isLoading = false;
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  TxFilter filter = TxFilter.all;
  bool tableMode = false;
  String query = '';

  StreamSubscription<List<TransactionModel>>? _sub;

  SharedPreferences? get _prefs =>
      Get.isRegistered<SharedPreferences>() ? Get.find<SharedPreferences>() : null;
  static const _txCacheKeyPrefix = 'personal_expense_tx_cache_';

  String _cacheKey([String? uidOverride]) {
    final uid = uidOverride ?? (Get.isRegistered<AuthService>() ? Get.find<AuthService>().currentUid : null);
    return '$_txCacheKeyPrefix${uid ?? 'guest'}';
  }

  void _loadCachedTransactions([String? uidOverride]) {
    try {
      final p = _prefs;
      if (p == null) return;
      final key = _cacheKey(uidOverride);
      final raw = p.getString(key);
      if (raw != null && raw.isNotEmpty && raw != '[]') {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final list = decoded
            .map((e) => TransactionModel.fromMap(Map<String, dynamic>.from(e as Map), (e['id'] ?? '').toString()))
            .toList();
        list.sort(_newestFirst);
        if (list.isNotEmpty) {
          entries = list;
          isLoading = false;
        }
      }
    } catch (e) {
      debugPrint('[TransactionsController] Error loading cached transactions: $e');
    }
  }

  void _saveCachedTransactions(List<TransactionModel> list, [String? uidOverride]) {
    try {
      final p = _prefs;
      if (p == null) return;
      final key = _cacheKey(uidOverride);
      final encoded = jsonEncode(list.map((m) => m.toJson()).toList());
      p.setString(key, encoded);
    } catch (e) {
      debugPrint('[TransactionsController] Error saving cached transactions: $e');
    }
  }

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
    _loadCachedTransactions();
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

      ever(auth.firebaseUser, (user) {
        if (user != null) {
          if (_boundUid != user.uid) {
            _sub?.cancel();
            _boundUid = null;
            _bindTransactions(user.uid);
          }
        } else {
          _sub?.cancel();
          _boundUid = null;
          entries = [];
          isLoading = false;
          update();
        }
      });

      if (auth.currentUid != null) {
        _bindTransactions(auth.currentUid!);
      }
    }
  }

  String? _boundUid;
  bool _isBinding = false;

  void _bindTransactions(String uid) {
    if (_boundUid == uid && entries.isNotEmpty) return;
    if (_boundUid == uid && _isBinding) return;
    _boundUid = uid;
    _isBinding = true;

    _loadCachedTransactions(uid);

    if (entries.isEmpty) {
      isLoading = true;
      update();
    } else {
      isLoading = false;
      update();
    }

    // Safety fallback: ensure loading spinner never hangs indefinitely
    Timer(const Duration(seconds: 3), () {
      if (isLoading) {
        isLoading = false;
        _isBinding = false;
        update();
      }
    });

    // 1. One-shot direct fetch for instant UI load
    final txService = Get.find<TransactionService>();
    txService.fetchUserTransactions(uid).then((list) {
      if (list.isNotEmpty) {
        entries = list;
        _saveCachedTransactions(list, uid);
      }
      isLoading = false;
      _isBinding = false;
      update();
    }).catchError((err) {
      debugPrint('[TransactionsController] fetchUserTransactions error: $err');
      isLoading = false;
      _isBinding = false;
      update();
    }).whenComplete(() {
      isLoading = false;
      _isBinding = false;
      update();
    });

    // 2. Realtime stream for live updates
    _sub?.cancel();
    _sub = txService.streamUserTransactions(uid).listen(
      (list) {
        if (list.isNotEmpty || entries.isEmpty) {
          entries = list;
          _saveCachedTransactions(list, uid);
        }
        isLoading = false;
        _isBinding = false;
        update();
      },
      onError: (err) {
        debugPrint('[TransactionsController] Stream error: $err');
        isLoading = false;
        _isBinding = false;
        update();
      },
    );
  }

  /// Pull-to-refresh handler for transactions
  Future<void> refreshTransactions() async {
    if (!Get.isRegistered<TransactionService>() || !Get.isRegistered<AuthService>()) return;
    final uid = Get.find<AuthService>().currentUid;
    if (uid == null || uid.isEmpty) return;
    try {
      final list = await Get.find<TransactionService>().fetchUserTransactions(uid);
      if (list.isNotEmpty || entries.isEmpty) {
        entries = list;
        _saveCachedTransactions(list, uid);
      }
    } catch (e) {
      debugPrint('[TransactionsController] refreshTransactions error: $e');
    } finally {
      isLoading = false;
      _isBinding = false;
      update();
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

  DateTime? get latestActiveMonth {
    if (entries.isEmpty) return null;
    final sorted = entries.toList()..sort(_newestFirst);
    return DateTime(sorted.first.date.year, sorted.first.date.month);
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
    // 1. Optimistically update local list and cache immediately for zero-lag UI response
    final i = entries.indexWhere((e) => e.id == m.id);
    if (i >= 0) {
      entries[i] = m;
    } else {
      entries.add(m);
    }
    entries.sort(_newestFirst);
    month = DateTime(m.date.year, m.date.month);
    _saveCachedTransactions(entries);
    update();

    // 2. Sync with cloud in background
    if (Get.isRegistered<TransactionService>()) {
      final txService = Get.find<TransactionService>();
      final exists = i >= 0;
      try {
        if (exists) {
          await txService.updateTransaction(m);
        } else {
          final realId = await txService.addTransaction(
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
          if (realId.isNotEmpty && realId != m.id) {
            final idx = entries.indexWhere((e) => e.id == m.id);
            if (idx >= 0) {
              entries[idx] = m.copyWith(id: realId);
              _saveCachedTransactions(entries);
              update();
            }
          }
        }
      } catch (e) {
        debugPrint('[TransactionsController] Background cloud sync error: $e');
        // Do not crash or rollback the local optimistic entry; it remains persisted in SharedPreferences & Firestore queue.
      }
    }
  }

  Future<void> remove(String id) async {
    final bool canShowDialog = Get.context != null;
    if (canShowDialog) {
      Get.dialog(
        PopScope(
          canPop: false,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Deleting transaction...'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );
    }

    // 1. Immediately remove from local list for instant UI response
    entries.removeWhere((e) => e.id == id);
    _saveCachedTransactions(entries);
    update();

    // 2. Perform reliable cloud delete with minimal delay for smooth UX
    if (Get.isRegistered<TransactionService>()) {
      try {
        await Future.wait([
          Get.find<TransactionService>().deleteTransaction(id),
          Future.delayed(const Duration(milliseconds: 500)),
        ]);
      } catch (e) {
        debugPrint('[TransactionsController] remove cloud error: $e');
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 400));
    }

    // Dismiss loading dialog if open
    if (canShowDialog && (Get.isDialogOpen ?? false)) {
      Get.back();
    }

    if (Get.context != null) {
      Get.snackbar(
        'Success'.tr,
        'Transaction deleted'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1F8A5B),
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 24),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 12,
      );
    }
  }
}
