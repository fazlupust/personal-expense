import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/entry_type.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/network_service.dart';
import '../../../data/services/transaction_service.dart';

enum TxFilter { all, income, expense }

class TransactionsController extends GetxController with WidgetsBindingObserver {
  TransactionsController();

  final searchCtrl = TextEditingController();
  List<TransactionModel> entries = [];
  bool isLoading = false;
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  TxFilter filter = TxFilter.all;
  bool tableMode = false;
  String query = '';
  bool isSyncingPending = false;

  int get unsyncedCount => entries.where((e) => !e.isSynced).length;
  List<TransactionModel> get unsyncedEntries => entries.where((e) => !e.isSynced).toList();

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
    WidgetsBinding.instance.addObserver(this);
    resetToCurrentMonth();
    _loadCachedTransactions();
    _initTransactions();

    if (Get.isRegistered<NetworkService>()) {
      ever(Get.find<NetworkService>().isOnline, (bool isOnline) {
        if (isOnline && unsyncedCount > 0) {
          syncPendingTransactions();
        }
      });
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    searchCtrl.dispose();
    _sub?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (unsyncedCount > 0) {
        syncPendingTransactions();
      }
    }
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
        // Retain any locally pending unsynced entries that have not reached the server yet
        final unsynced = entries.where((e) => !e.isSynced).toList();
        final serverMap = {for (final tx in list) tx.id: tx};
        final merged = <TransactionModel>[...list];
        for (final u in unsynced) {
          if (!serverMap.containsKey(u.id)) {
            merged.add(u);
          }
        }
        merged.sort(_newestFirst);
        entries = merged;
        _saveCachedTransactions(entries, uid);
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

  /// Pull-to-refresh & manual sync handler
  Future<void> refreshTransactions() async {
    if (!Get.isRegistered<TransactionService>() || !Get.isRegistered<AuthService>()) return;
    final uid = Get.find<AuthService>().currentUid;
    if (uid == null || uid.isEmpty) return;

    // 1. If there are any pending offline entries, push them to the cloud first
    if (unsyncedCount > 0) {
      await syncPendingTransactions();
    }

    // 2. Fetch fresh data from Firestore cloud and merge
    try {
      final list = await Get.find<TransactionService>().fetchUserTransactions(uid);
      if (list.isNotEmpty || entries.isEmpty) {
        final unsynced = entries.where((e) => !e.isSynced).toList();
        final serverMap = {for (final tx in list) tx.id: tx};
        final merged = <TransactionModel>[...list];
        for (final u in unsynced) {
          if (!serverMap.containsKey(u.id)) {
            merged.add(u);
          }
        }
        merged.sort(_newestFirst);
        entries = merged;
        _saveCachedTransactions(entries, uid);
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

  static String parseSyncError(dynamic e) {
    if (e == null) return 'অজানা কারণ (Unknown error)';
    final s = e.toString();
    if (s.contains('User not logged in') || s.contains('user-not-found')) {
      return 'ইউজার লগইন করা নেই (User not logged in)';
    }
    if (s.contains('permission-denied')) {
      return 'ফায়ারবেস অনুমতি সমস্যা (Permission Denied / Auth Mismatch)';
    }
    if (s.contains('TimeoutException') || s.contains('timed out')) {
      return 'সার্ভার টাইমআউট: ইন্টারনেট অত্যন্ত ধীরগতির (Server response timed out)';
    }
    if (s.contains('SocketException') || s.contains('Network') || s.contains('network-request-failed')) {
      return 'ইন্টারনেট সংযোগ নেই বা বিচ্ছিন্ন (No internet / Socket error)';
    }
    if (s.contains('unavailable')) {
      return 'ফায়ারবেস ক্লাউড সার্ভিস সাময়িকভাবে আনরিচেবল (Service unavailable)';
    }
    if (s.contains('quota-exceeded')) {
      return 'ফায়ারবেস কোটা সীমা অতিক্রম করেছে (Quota exceeded)';
    }
    return s.replaceAll('Exception:', '').trim();
  }

  Future<void> save(TransactionModel m) async {
    // 1. Optimistically update local list and cache immediately for zero-lag UI response
    final i = entries.indexWhere((e) => e.id == m.id);
    final exists = i >= 0;
    // Local optimistic entry starts as isSynced: false until confirmed by cloud
    final localTx = m.copyWith(isSynced: false);

    if (exists) {
      entries[i] = localTx;
    } else {
      entries.add(localTx);
    }
    entries.sort(_newestFirst);
    month = DateTime(m.date.year, m.date.month);
    _saveCachedTransactions(entries);
    update();

    // 2. Sync with cloud in background
    if (Get.isRegistered<TransactionService>()) {
      final txService = Get.find<TransactionService>();
      try {
        if (exists) {
          await txService.updateTransaction(m);
          final idx = entries.indexWhere((e) => e.id == m.id);
          if (idx >= 0) {
            entries[idx] = entries[idx].copyWith(isSynced: true, syncError: null);
            _saveCachedTransactions(entries);
            update();
          }
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
          final idx = entries.indexWhere((e) => e.id == m.id);
          if (idx >= 0) {
            entries[idx] = entries[idx].copyWith(
              id: realId.isNotEmpty ? realId : m.id,
              isSynced: true,
              syncError: null,
            );
            _saveCachedTransactions(entries);
            update();
          }
        }
      } catch (e) {
        final reason = parseSyncError(e);
        debugPrint('[TransactionsController] Background cloud sync error: $e ($reason)');
        final idx = entries.indexWhere((e) => e.id == m.id);
        if (idx >= 0) {
          entries[idx] = entries[idx].copyWith(isSynced: false, syncError: reason);
          _saveCachedTransactions(entries);
          update();
        }
      }
    }
  }

  /// Retries syncing all unsynced (offline) transactions to Firestore
  Future<void> syncPendingTransactions() async {
    if (isSyncingPending) return;
    if (!Get.isRegistered<TransactionService>() || !Get.isRegistered<AuthService>()) return;
    final uid = Get.find<AuthService>().currentUid;
    if (uid == null || uid.isEmpty) return;

    final pending = entries.where((e) => !e.isSynced).toList();
    if (pending.isEmpty) return;

    isSyncingPending = true;
    update();

    final txService = Get.find<TransactionService>();
    int syncedCount = 0;
    int failedCount = 0;
    String? lastFailureReason;

    for (final tx in pending) {
      try {
        final isTempId = int.tryParse(tx.id) != null && tx.id.length >= 10;
        if (isTempId) {
          final realId = await txService.addTransaction(
            categoryId: tx.categoryId,
            categoryNameBn: tx.categoryNameBn,
            categoryNameEn: tx.categoryNameEn,
            type: tx.type,
            amount: tx.amount,
            noteBn: tx.noteBn,
            noteEn: tx.noteEn,
            date: tx.date,
            account: tx.account,
            latitude: tx.latitude,
            longitude: tx.longitude,
            deviceInfo: tx.deviceInfo,
          );
          final idx = entries.indexWhere((e) => e.id == tx.id);
          if (idx >= 0) {
            entries[idx] = tx.copyWith(
              id: realId.isNotEmpty ? realId : tx.id,
              isSynced: true,
              syncError: null,
            );
            syncedCount++;
          }
        } else {
          await txService.updateTransaction(tx);
          final idx = entries.indexWhere((e) => e.id == tx.id);
          if (idx >= 0) {
            entries[idx] = tx.copyWith(isSynced: true, syncError: null);
            syncedCount++;
          }
        }
      } catch (e) {
        final reason = parseSyncError(e);
        lastFailureReason = reason;
        failedCount++;
        debugPrint('[TransactionsController] Sync failed for ${tx.id}: $e ($reason)');
        final idx = entries.indexWhere((e) => e.id == tx.id);
        if (idx >= 0) {
          entries[idx] = tx.copyWith(isSynced: false, syncError: reason);
        }
      }
    }

    _saveCachedTransactions(entries, uid);
    isSyncingPending = false;
    update();

    if (syncedCount > 0 && Get.context != null) {
      final isBn = Get.locale?.languageCode == 'bn';
      Get.snackbar(
        isBn ? 'সিঙ্ক সম্পন্ন' : 'Sync Complete',
        isBn
            ? '$syncedCountটি অফলাইন লেনদেন সফলভাবে ক্লাউডে সিঙ্ক হয়েছে।'
            : '$syncedCount offline entries synced to cloud successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1F8A5B),
        colorText: Colors.white,
        icon: const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 24),
        duration: const Duration(seconds: 3),
      );
    } else if (failedCount > 0 && syncedCount == 0 && Get.context != null) {
      final isBn = Get.locale?.languageCode == 'bn';
      Get.snackbar(
        isBn ? 'সিঙ্ক ব্যর্থ হয়েছে' : 'Sync Failed',
        isBn
            ? 'আসল কারণ: ${lastFailureReason ?? 'নেটওয়ার্ক বা সার্ভার সমস্যা'}'
            : 'Exact reason: ${lastFailureReason ?? 'Network or server error'}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
        icon: const Icon(Icons.sync_problem_rounded, color: Colors.white, size: 24),
        duration: const Duration(seconds: 5),
      );
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
