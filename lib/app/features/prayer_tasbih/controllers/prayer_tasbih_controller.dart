import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/tasbih_entry_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/prayer_time_service.dart';

part 'prayer_tasbih_presets.dart';
part 'prayer_tasbih_prayer_times.dart';
part 'prayer_tasbih_analytics.dart';
part 'prayer_tasbih_firestore_sync.dart';

enum ZikirCategory {
  all,
  prayer,         // নামাজ পরবর্তী
  morningEvening, // সকাল-সন্ধ্যা
  forgiveness,    // তওবা ও ইস্তিগফার
  salawat,        // দুরুদ শরীফ
  dua,            // দোয়া ও অন্যান্য
}

enum TasbihTimeFilter {
  today,       // আজ
  thisWeek,    // বিগত ৭ দিন
  thisMonth,   // এই মাস
  allTime,     // সর্বমোট
}

class ZikirItem {
  final String id;
  final String arabic;
  final String titleBn;
  final String titleEn;
  final String? pronunciationBn;
  final String meaningBn;
  final String meaningEn;
  final int defaultTarget;
  final String? benefitBn;
  final bool isCustom;
  final ZikirCategory category;

  const ZikirItem({
    required this.id,
    required this.arabic,
    required this.titleBn,
    required this.titleEn,
    this.pronunciationBn,
    required this.meaningBn,
    required this.meaningEn,
    this.defaultTarget = 33,
    this.benefitBn,
    this.isCustom = false,
    this.category = ZikirCategory.prayer,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'arabic': arabic,
        'titleBn': titleBn,
        'titleEn': titleEn,
        if (pronunciationBn != null) 'pronunciationBn': pronunciationBn,
        'meaningBn': meaningBn,
        'meaningEn': meaningEn,
        'defaultTarget': defaultTarget,
        'benefitBn': benefitBn,
        'isCustom': isCustom,
        'category': category.name,
      };

  factory ZikirItem.fromJson(Map<String, dynamic> json) => ZikirItem(
        id: json['id'] as String,
        arabic: json['arabic'] as String? ?? '',
        titleBn: json['titleBn'] as String? ?? '',
        titleEn: json['titleEn'] as String? ?? '',
        pronunciationBn: json['pronunciationBn'] as String?,
        meaningBn: json['meaningBn'] as String? ?? '',
        meaningEn: json['meaningEn'] as String? ?? '',
        defaultTarget: json['defaultTarget'] as int? ?? 33,
        benefitBn: json['benefitBn'] as String?,
        isCustom: json['isCustom'] as bool? ?? false,
        category: ZikirCategory.values.firstWhere(
          (c) => c.name == (json['category'] as String? ?? 'prayer'),
          orElse: () => ZikirCategory.prayer,
        ),
      );
}

class PrayerTasbihController extends GetxController {
  static PrayerTasbihController get to => Get.find<PrayerTasbihController>();

  // --- User Scope & Isolation ---
  String? _overrideUid;
  String get _currentUid =>
      _overrideUid ??
      (Get.isRegistered<AuthService>()
          ? (Get.find<AuthService>().currentUid ?? '')
          : '');

  SharedPreferences? _prefs;

  Future<void> loadForUserForTesting(String uid) async {
    if (_currentUid.isNotEmpty && _todayTotal > 0) {
      await _persistTasbihData(_currentUid);
    }
    _overrideUid = uid;
    await _loadTasbihData(uid);
  }

  String _userKey(String base, [String? uidOverride]) {
    final uid = uidOverride ?? _currentUid;
    return uid.isNotEmpty ? '${base}_$uid' : base;
  }

  // --- Prayer Times State ---
  late BangladeshLocation _selectedLocation;
  BangladeshLocation get selectedLocation => _selectedLocation;

  bool _isHanafi = true;
  bool get isHanafi => _isHanafi;

  int _hijriOffsetDays = -1;
  int get hijriOffsetDays => _hijriOffsetDays;

  late DailyPrayerSchedule _schedule;
  DailyPrayerSchedule get schedule => _schedule;

  Timer? _countdownTimer;
  String _timeUntilNextPrayer = '';
  String get timeUntilNextPrayer => _timeUntilNextPrayer;

  PrayerTimeItem? _nextPrayer;
  PrayerTimeItem? get nextPrayer => _nextPrayer;

  PrayerTimeItem? _currentWaqt;
  PrayerTimeItem? get currentWaqt => _currentWaqt;

  // --- Tasbih Counter State ---
  static const List<ZikirItem> presetZikirs = _presetZikirs;

  final List<ZikirItem> _allZikirs = <ZikirItem>[];
  List<ZikirItem> get allZikirs => List.unmodifiable(_allZikirs);

  /// Returns all zikirs sorted descending by lifetime recitation count (most read first).
  /// Ties maintain initial preset order.
  List<ZikirItem> get sortedZikirs {
    final list = List<ZikirItem>.from(_allZikirs);
    list.sort((a, b) {
      final countA = _zikirLifetimeCounts[a.id] ?? 0;
      final countB = _zikirLifetimeCounts[b.id] ?? 0;
      if (countB != countA) {
        return countB.compareTo(countA);
      }
      return _allZikirs.indexOf(a).compareTo(_allZikirs.indexOf(b));
    });
    return list;
  }

  late ZikirItem _selectedZikir;
  ZikirItem get selectedZikir => _selectedZikir;

  int _currentCount = 0;
  int get currentCount => _currentCount;

  int _targetCount = 33;
  int get targetCount => _targetCount;

  int _completedCycles = 0;
  int get completedCycles => _completedCycles;

  int _todayTotal = 0;
  int get todayTotal => _todayTotal;

  int _lifetimeTotal = 0;
  int get lifetimeTotal => _lifetimeTotal;

  // --- Per-Zikir Recitation Counters & History ---
  final Map<String, int> _zikirLifetimeCounts = <String, int>{};
  Map<String, int> get zikirLifetimeCounts => Map.unmodifiable(_zikirLifetimeCounts);

  final Map<String, Map<String, int>> _zikirDailyCounts = <String, Map<String, int>>{};

  // Filter States for Analytics
  TasbihTimeFilter _selectedTimeFilter = TasbihTimeFilter.today;
  TasbihTimeFilter get selectedTimeFilter => _selectedTimeFilter;

  ZikirCategory _selectedCategoryFilter = ZikirCategory.all;
  ZikirCategory get selectedCategoryFilter => _selectedCategoryFilter;

  bool _isVibrationEnabled = true;
  bool get isVibrationEnabled => _isVibrationEnabled;

  bool _isSoundEnabled = true;
  bool get isSoundEnabled => _isSoundEnabled;

  bool _isCountHidden = false;
  bool get isCountHidden => _isCountHidden;

  bool _isZikirCardHidden = true;
  bool get isZikirCardHidden => _isZikirCardHidden;

  bool _isProhibitedAlertOn = true;
  bool get isProhibitedAlertOn => _isProhibitedAlertOn;

  int _prohibitedBufferMinutes = 15;
  int get prohibitedBufferMinutes => _prohibitedBufferMinutes;

  int _activeTab = 0;
  int get activeTab => _activeTab;

  final RxList<TasbihEntryModel> _historyEntries = <TasbihEntryModel>[].obs;
  List<TasbihEntryModel> get historyEntries => _historyEntries;

  final RxnString _selectedHistoryDate = RxnString(null);
  String? get selectedHistoryDate => _selectedHistoryDate.value;
  void selectHistoryDate(String? date) {
    _selectedHistoryDate.value = date;
    update();
  }

  final Rxn<DateTime> _selectedHistoryMonth =
      Rxn<DateTime>(DateTime(DateTime.now().year, DateTime.now().month));
  DateTime? get selectedHistoryMonth => _selectedHistoryMonth.value;

  void setHistoryMonth(DateTime? month) {
    if (month == null) {
      _selectedHistoryMonth.value = null;
    } else {
      _selectedHistoryMonth.value = DateTime(month.year, month.month);
    }
    update();
  }

  void previousHistoryMonth() {
    final current = _selectedHistoryMonth.value ?? DateTime.now();
    _selectedHistoryMonth.value = DateTime(current.year, current.month - 1);
    update();
  }

  void nextHistoryMonth() {
    final current = _selectedHistoryMonth.value ?? DateTime.now();
    final next = DateTime(current.year, current.month + 1);
    final now = DateTime.now();
    if (!next.isAfter(DateTime(now.year, now.month))) {
      _selectedHistoryMonth.value = next;
      update();
    }
  }

  bool _isSyncingHistory = false;
  bool get isSyncingHistory => _isSyncingHistory;

  Timer? _firestoreDebounceTimer;

  Map<String, List<TasbihEntryModel>> get groupedHistoryEntries {
    final map = <String, List<TasbihEntryModel>>{};
    final selectedMonth = _selectedHistoryMonth.value;
    for (final entry in _historyEntries) {
      if (selectedMonth != null) {
        final parts = entry.date.split('-');
        if (parts.length >= 2) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          if (y != selectedMonth.year || m != selectedMonth.month) {
            continue;
          }
        }
      }
      map.putIfAbsent(entry.date, () => []).add(entry);
    }
    return map;
  }

  int get selectedMonthTotal {
    int sum = 0;
    final selectedMonth = _selectedHistoryMonth.value;
    _zikirDailyCounts.forEach((dateKey, dayMap) {
      if (selectedMonth != null) {
        final parts = dateKey.split('-');
        if (parts.length >= 2) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          if (y != selectedMonth.year || m != selectedMonth.month) {
            return;
          }
        }
      }
      dayMap.forEach((_, c) => sum += c);
    });
    return sum;
  }

  Map<String, int> get dayTotals {
    final map = <String, int>{};
    _zikirDailyCounts.forEach((dateKey, dayMap) {
      int total = 0;
      dayMap.forEach((_, c) => total += c);
      map[dateKey] = total;
    });
    return map;
  }

  @override
  void onInit() {
    super.onInit();
    _selectedLocation = BangladeshLocation.defaultLocation;
    _allZikirs.addAll(presetZikirs);
    _selectedZikir = presetZikirs.first;
    _targetCount = _selectedZikir.defaultTarget;

    _recalculatePrayerTimes();
    _loadTasbihData();
    _bindAuth();

    if (!Get.testMode) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updatePrayerCountdown();
      });
    }
  }

  void _bindAuth() {
    if (Get.isRegistered<AuthService>()) {
      final auth = Get.find<AuthService>();
      ever(auth.firebaseUser, (user) async {
        if (user != null) {
          await _loadTasbihData(user.uid);
          await _syncFromFirestore(user.uid);
          if (_todayTotal > 0 || _zikirDailyCounts.isNotEmpty) {
            _flushToFirestore(user.uid);
          }
        } else {
          _resetUserScopedData();
        }
      });
      if (auth.currentUid != null && auth.currentUid!.isNotEmpty) {
        _syncFromFirestore(auth.currentUid!).then((_) {
          if (_todayTotal > 0 || _zikirDailyCounts.isNotEmpty) {
            _flushToFirestore(auth.currentUid!);
          }
        });
      }
    }
  }

  void _resetUserScopedData() {
    _currentCount = 0;
    _todayTotal = 0;
    _lifetimeTotal = 0;
    _completedCycles = 0;
    _zikirLifetimeCounts.clear();
    _zikirDailyCounts.clear();
    _isCountHidden = false;
    _isZikirCardHidden = true;
    update();
  }

  void stopTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    _firestoreDebounceTimer?.cancel();
    final uid = _currentUid;
    if (uid.isNotEmpty) {
      _flushToFirestore(uid);
    }
    super.onClose();
  }

  void setActiveTab(int index) {
    _activeTab = index;
    update();
  }

  // --- Tasbih Counter Controls ---
  void selectZikir(ZikirItem zikir) {
    _selectedZikir = zikir;
    _targetCount = zikir.defaultTarget;
    _currentCount = 0;
    _completedCycles = 0;
    update();
  }

  void setTarget(int target) {
    _targetCount = target;
    _currentCount = 0;
    _completedCycles = 0;
    update();
  }

  void increment() {
    _currentCount++;
    _todayTotal++;
    _lifetimeTotal++;

    final zId = _selectedZikir.id;
    _zikirLifetimeCounts[zId] = (_zikirLifetimeCounts[zId] ?? 0) + 1;
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dayMap = _zikirDailyCounts.putIfAbsent(todayKey, () => <String, int>{});
    dayMap[zId] = (dayMap[zId] ?? 0) + 1;

    final cycleCompleted = _targetCount > 0 && (_currentCount % _targetCount == 0);

    if (_isVibrationEnabled) {
      if (cycleCompleted) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }

    if (cycleCompleted) {
      _completedCycles++;
      // Do NOT reset _currentCount to 0! Allow user to keep counting continuously (e.g. 34, 35 ... 100+).
      if (Get.context != null) {
        Get.snackbar(
          '🎉 মাশাআল্লাহ!'.tr,
          'আপনার $_targetCount বারের টার্গেট পূর্ণ হয়েছে (রাউন্ড: $_completedCycles)!'.tr,
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF1B5E20),
          colorText: Colors.white,
          icon: const Icon(Icons.celebration_rounded, color: Colors.white, size: 28),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: 12,
        );
      }
    }

    _persistTasbihData();
    _rebuildHistoryEntriesLocal();
    _scheduleFirestoreSync();
    update();
  }

  void decrement() {
    if (_currentCount > 0) {
      _currentCount--;
      if (_todayTotal > 0) _todayTotal--;
      if (_lifetimeTotal > 0) _lifetimeTotal--;

      final zId = _selectedZikir.id;
      if ((_zikirLifetimeCounts[zId] ?? 0) > 0) {
        _zikirLifetimeCounts[zId] = _zikirLifetimeCounts[zId]! - 1;
      }
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      if ((_zikirDailyCounts[todayKey]?[zId] ?? 0) > 0) {
        _zikirDailyCounts[todayKey]![zId] = _zikirDailyCounts[todayKey]![zId]! - 1;
      }

      if (_isVibrationEnabled) {
        HapticFeedback.selectionClick();
      }
      _persistTasbihData();
      _rebuildHistoryEntriesLocal();
      _scheduleFirestoreSync();
      update();
    }
  }

  void reset() {
    _currentCount = 0;
    _completedCycles = 0;
    if (_isVibrationEnabled) {
      HapticFeedback.mediumImpact();
    }
    update();
  }

  void toggleVibration() {
    _isVibrationEnabled = !_isVibrationEnabled;
    _persistSettings();
    update();
  }

  void toggleSound() {
    _isSoundEnabled = !_isSoundEnabled;
    _persistSettings();
    update();
  }

  Future<void> toggleCountVisibility() async {
    _isCountHidden = !_isCountHidden;
    update();
    await _persistSettings();
  }

  Future<void> setCountHidden(bool val) async {
    _isCountHidden = val;
    update();
    await _persistSettings();
  }

  Future<void> toggleZikirCardVisibility() async {
    _isZikirCardHidden = !_isZikirCardHidden;
    update();
    await _persistSettings();
  }

  Future<void> setZikirCardHidden(bool val) async {
    _isZikirCardHidden = val;
    update();
    await _persistSettings();
  }
}
