part of 'prayer_tasbih_controller.dart';

extension PrayerTasbihAnalytics on PrayerTasbihController {
  void setTimeFilter(TasbihTimeFilter filter) {
    _selectedTimeFilter = filter;
    update();
  }

  void setCategoryFilter(ZikirCategory category) {
    _selectedCategoryFilter = category;
    update();
  }

  /// Get recitation count of a specific Zikir by time filter
  int getZikirCount(String zikirId, [TasbihTimeFilter? filter]) {
    if (filter == null && _selectedHistoryDate.value != null) {
      return _zikirDailyCounts[_selectedHistoryDate.value]?[zikirId] ?? 0;
    }
    final f = filter ?? _selectedTimeFilter;
    switch (f) {
      case TasbihTimeFilter.today:
        final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
        return _zikirDailyCounts[todayKey]?[zikirId] ?? 0;
      case TasbihTimeFilter.thisWeek:
        int sum = 0;
        final now = DateTime.now();
        for (int i = 0; i < 7; i++) {
          final d = now.subtract(Duration(days: i));
          final key = DateFormat('yyyy-MM-dd').format(d);
          sum += _zikirDailyCounts[key]?[zikirId] ?? 0;
        }
        return sum;
      case TasbihTimeFilter.thisMonth:
        int sum = 0;
        final now = DateTime.now();
        final prefix = DateFormat('yyyy-MM').format(now);
        _zikirDailyCounts.forEach((dateKey, map) {
          if (dateKey.startsWith(prefix)) {
            sum += map[zikirId] ?? 0;
          }
        });
        return sum;
      case TasbihTimeFilter.allTime:
        return _zikirLifetimeCounts[zikirId] ?? 0;
    }
  }

  int getZikirTodayCount(String zikirId) =>
      getZikirCount(zikirId, TasbihTimeFilter.today);

  int getZikirLifetimeCount(String zikirId) =>
      _zikirLifetimeCounts[zikirId] ?? 0;

  /// Get list of Zikirs matching the active category filter
  List<ZikirItem> get filteredZikirs {
    if (_selectedCategoryFilter == ZikirCategory.all) {
      return allZikirs;
    }
    return allZikirs.where((z) => z.category == _selectedCategoryFilter).toList();
  }

  /// Total recitations matching active time and category filters
  int getTotalFilteredCount() {
    int total = 0;
    for (final z in filteredZikirs) {
      total += getZikirCount(z.id);
    }
    return total;
  }

  /// Get list of Zikirs sorted by recitation count (highest first)
  List<ZikirItem> getSortedZikirsByCount({TasbihTimeFilter? filter}) {
    final list = List<ZikirItem>.from(filteredZikirs);
    list.sort((a, b) => getZikirCount(b.id, filter).compareTo(getZikirCount(a.id, filter)));
    return list;
  }

  /// Get the maximum count among filtered zikirs for relative progress indicators
  int getMaxZikirCount({TasbihTimeFilter? filter}) {
    int max = 0;
    for (final z in filteredZikirs) {
      final cnt = getZikirCount(z.id, filter);
      if (cnt > max) max = cnt;
    }
    return max;
  }

  String getCategoryName(ZikirCategory category) {
    final isBn = Get.locale?.languageCode == 'bn';
    switch (category) {
      case ZikirCategory.all:
        return isBn ? 'সকল' : 'All';
      case ZikirCategory.prayer:
        return isBn ? 'নামাজ পরবর্তী' : 'After Prayer';
      case ZikirCategory.morningEvening:
        return isBn ? 'সকাল-সন্ধ্যা' : 'Morning & Evening';
      case ZikirCategory.forgiveness:
        return isBn ? 'তওবা ও ইস্তিগফার' : 'Forgiveness';
      case ZikirCategory.salawat:
        return isBn ? 'দুরুদ শরীফ' : 'Salawat';
      case ZikirCategory.dua:
        return isBn ? 'দোয়া ও মুনাজাত' : 'Duas';
    }
  }

  String getTimeFilterName(TasbihTimeFilter filter) {
    final isBn = Get.locale?.languageCode == 'bn';
    switch (filter) {
      case TasbihTimeFilter.today:
        return isBn ? 'আজ' : 'Today';
      case TasbihTimeFilter.thisWeek:
        return isBn ? 'বিগত ৭ দিন' : 'Last 7 Days';
      case TasbihTimeFilter.thisMonth:
        return isBn ? 'এই মাস' : 'This Month';
      case TasbihTimeFilter.allTime:
        return isBn ? 'সর্বমোট' : 'All Time';
    }
  }
}
