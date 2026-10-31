part of 'prayer_tasbih_controller.dart';

enum TrackerFilter {
  all,
  missing,
  fajr,
  dhuhr,
  asr,
  maghrib,
  isha,
  full5,
}

class TrackerPrayerItem {
  final String key;
  final String nameEn;
  final String nameBn;
  final String arabicName;
  final IconData icon;

  const TrackerPrayerItem({
    required this.key,
    required this.nameEn,
    required this.nameBn,
    required this.arabicName,
    required this.icon,
  });
}

const List<TrackerPrayerItem> kTrackerPrayers = [
  TrackerPrayerItem(
    key: 'fajr',
    nameEn: 'Fajr',
    nameBn: 'ফজর',
    arabicName: 'الفَجْر',
    icon: Icons.wb_twilight_rounded,
  ),
  TrackerPrayerItem(
    key: 'dhuhr',
    nameEn: 'Dhuhr',
    nameBn: 'যোহর',
    arabicName: 'الظُّهْر',
    icon: Icons.wb_sunny_rounded,
  ),
  TrackerPrayerItem(
    key: 'asr',
    nameEn: 'Asr',
    nameBn: 'আসর',
    arabicName: 'العَصْر',
    icon: Icons.wb_sunny_outlined,
  ),
  TrackerPrayerItem(
    key: 'maghrib',
    nameEn: 'Maghrib',
    nameBn: 'মাগরিব',
    arabicName: 'المَغْرِب',
    icon: Icons.nights_stay_outlined,
  ),
  TrackerPrayerItem(
    key: 'isha',
    nameEn: 'Isha',
    nameBn: 'এশা',
    arabicName: 'العِشَاء',
    icon: Icons.bedtime_rounded,
  ),
];

extension PrayerTasbihTracker on PrayerTasbihController {
  // --- Prayer Tracking Query & Mutation Methods ---

  /// Check if a specific prayer is marked as completed on a given date (yyyy-MM-dd)
  bool isPrayerCompleted(String dateStr, String prayerKey) {
    return _prayerTrackerRecords[dateStr]?[prayerKey] ?? false;
  }

  /// Toggle prayer completion state for a given date
  Future<void> togglePrayer(String dateStr, String prayerKey) async {
    if (_loadDataFuture != null) {
      await _loadDataFuture;
    }
    final currentMap = _prayerTrackerRecords[dateStr] ?? <String, bool>{};
    final newMap = Map<String, bool>.from(currentMap);
    final currentState = newMap[prayerKey] ?? false;
    newMap[prayerKey] = !currentState;
    _prayerTrackerRecords[dateStr] = newMap;

    await _persistTasbihData();
    _scheduleFirestoreSync();
    update();
  }

  /// Set status for all 5 prayers on a given date (e.g. mark all completed)
  Future<void> setDayAllPrayers(String dateStr, bool completed) async {
    if (_loadDataFuture != null) {
      await _loadDataFuture;
    }
    final newMap = <String, bool>{};
    for (final prayer in kTrackerPrayers) {
      newMap[prayer.key] = completed;
    }
    _prayerTrackerRecords[dateStr] = newMap;

    await _persistTasbihData();
    _scheduleFirestoreSync();
    update();
  }

  /// Total prayers completed on a given date (0-5)
  int getCompletedCountForDate(String dateStr) {
    final map = _prayerTrackerRecords[dateStr];
    if (map == null || map.isEmpty) return 0;
    int count = 0;
    for (final p in kTrackerPrayers) {
      if (map[p.key] == true) count++;
    }
    return count;
  }

  /// List of prayer keys not completed for a given date
  List<String> getMissingPrayersForDate(String dateStr) {
    final map = _prayerTrackerRecords[dateStr] ?? <String, bool>{};
    final missing = <String>[];
    for (final p in kTrackerPrayers) {
      if (map[p.key] != true) {
        missing.add(p.key);
      }
    }
    return missing;
  }

  /// List of TrackerPrayerItems missing for a given date
  List<TrackerPrayerItem> getMissingPrayerItemsForDate(String dateStr) {
    final map = _prayerTrackerRecords[dateStr] ?? <String, bool>{};
    final missing = <TrackerPrayerItem>[];
    for (final p in kTrackerPrayers) {
      if (map[p.key] != true) {
        missing.add(p);
      }
    }
    return missing;
  }

  /// Whether all 5 prayers are completed on a given date
  bool isDayFullSalat(String dateStr) {
    return getCompletedCountForDate(dateStr) == kTrackerPrayers.length;
  }

  /// Total prayers completed across the specified month
  int getMonthlyCompletedPrayersCount(DateTime month) {
    final prefix = DateFormat('yyyy-MM').format(month);
    int sum = 0;
    _prayerTrackerRecords.forEach((dateKey, map) {
      if (dateKey.startsWith(prefix)) {
        for (final p in kTrackerPrayers) {
          if (map[p.key] == true) sum++;
        }
      }
    });
    return sum;
  }

  /// Number of days where all 5 prayers were completed in the specified month
  int getMonthlyFullSalatDaysCount(DateTime month) {
    final prefix = DateFormat('yyyy-MM').format(month);
    int count = 0;
    _prayerTrackerRecords.forEach((dateKey, map) {
      if (dateKey.startsWith(prefix)) {
        int dayCount = 0;
        for (final p in kTrackerPrayers) {
          if (map[p.key] == true) dayCount++;
        }
        if (dayCount == kTrackerPrayers.length) {
          count++;
        }
      }
    });
    return count;
  }

  /// Total expected prayers in the month up to current day (or end of month if past month)
  int getMonthlyExpectedPrayersCount(DateTime month) {
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final isFutureMonth = DateTime(month.year, month.month).isAfter(DateTime(now.year, now.month));
    if (isFutureMonth) return 0;

    final days = isCurrentMonth ? now.day : DateTime(month.year, month.month + 1, 0).day;
    return days * kTrackerPrayers.length;
  }

  /// Total prayers missed in the month up to current day (or end of month if past month)
  int getMonthlyMissingPrayersCount(DateTime month) {
    final expected = getMonthlyExpectedPrayersCount(month);
    final completed = getMonthlyCompletedPrayersCount(month);
    final missed = expected - completed;
    return missed >= 0 ? missed : 0;
  }

  /// Completion rate percentage (0.0 to 100.0)
  double getMonthlyCompletionRate(DateTime month) {
    final expected = getMonthlyExpectedPrayersCount(month);
    if (expected <= 0) return 0.0;
    final completed = getMonthlyCompletedPrayersCount(month);
    return ((completed / expected) * 100).clamp(0.0, 100.0);
  }

  /// Count of completions per prayer (Fajr, Dhuhr, etc.) in the specified month
  Map<String, int> getMonthlyWaqtCompletionCounts(DateTime month) {
    final prefix = DateFormat('yyyy-MM').format(month);
    final map = <String, int>{for (final p in kTrackerPrayers) p.key: 0};
    _prayerTrackerRecords.forEach((dateKey, dayMap) {
      if (dateKey.startsWith(prefix)) {
        for (final p in kTrackerPrayers) {
          if (dayMap[p.key] == true) {
            map[p.key] = (map[p.key] ?? 0) + 1;
          }
        }
      }
    });
    return map;
  }

  /// Helper to get formatted string for today's date key (yyyy-MM-dd)
  String get todayDateKey => DateFormat('yyyy-MM-dd').format(DateTime.now());
}
