part of 'prayer_tasbih_controller.dart';

extension PrayerTasbihPrayerTimes on PrayerTasbihController {
  // --- Prayer Times Methods ---
  void _recalculatePrayerTimes() {
    final now = DateTime.now();
    _schedule = PrayerTimeCalculator.calculate(
      date: now,
      location: _selectedLocation,
      isHanafi: _isHanafi,
      hijriAdjustmentDays: _hijriOffsetDays,
    );
    _updatePrayerCountdown();
  }

  void _updatePrayerCountdown() {
    final now = DateTime.now();
    // Midnight rollover: recalculate if day changed
    if (now.year != _schedule.date.year ||
        now.month != _schedule.date.month ||
        now.day != _schedule.date.day) {
      _recalculatePrayerTimes();
      return;
    }

    final newCurrentWaqt = _schedule.getCurrentWaqt(now);
    final newNextPrayer = _schedule.getNextPrayer(now);

    var targetTime = newNextPrayer.time;
    if (targetTime.isBefore(now)) {
      targetTime = targetTime.add(const Duration(days: 1));
    }

    final diff = targetTime.difference(now);
    final formattedTime = PrayerTimeCalculator.formatRemainingTime(diff);

    final hasChanged = _currentWaqt?.prayer != newCurrentWaqt.prayer ||
        _nextPrayer?.prayer != newNextPrayer.prayer ||
        _timeUntilNextPrayer != formattedTime;

    if (hasChanged) {
      _currentWaqt = newCurrentWaqt;
      _nextPrayer = newNextPrayer;
      _timeUntilNextPrayer = formattedTime;
      update();
    }
  }

  void setLocation(BangladeshLocation location) {
    _selectedLocation = location;
    _recalculatePrayerTimes();
    _saveLocation();
  }

  void toggleAsrMethod() {
    _isHanafi = !_isHanafi;
    _recalculatePrayerTimes();
    _saveLocation();
  }

  Future<void> setHijriOffset(int offset) async {
    _hijriOffsetDays = offset;
    _recalculatePrayerTimes();
    update();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userKey('prayer_hijri_offset', _currentUid), _hijriOffsetDays);
    syncOnlineHijriDate(force: true);
  }

  Future<void> syncOnlineHijriDate({bool force = false}) async {
    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    final cacheKey = 'cached_online_hijri_$todayKey';

    final prefs = await SharedPreferences.getInstance();

    // 1. Check local cache first if not forced
    if (!force) {
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson != null) {
        try {
          final map = jsonDecode(cachedJson) as Map<String, dynamic>;
          final cachedDay = map['day'] as int;
          final cachedMonth = map['month'] as int;
          final cachedYear = map['year'] as int;
          final hijriInfo = PrayerTimeCalculator.createHijriInfo(
            day: cachedDay,
            month: cachedMonth,
            year: cachedYear,
          );
          _applyHijriInfo(hijriInfo, isOnline: true);
          return;
        } catch (_) {}
      }
    }

    // 2. Fetch online from Aladhan API (Bangladesh method)
    final onlineInfo = await PrayerTimeCalculator.fetchOnlineHijriDate(
      now,
      adjustmentDays: _hijriOffsetDays,
    );

    if (onlineInfo != null) {
      await prefs.setString(
        cacheKey,
        jsonEncode({
          'day': onlineInfo.day,
          'month': onlineInfo.month,
          'year': onlineInfo.year,
        }),
      );
      _applyHijriInfo(onlineInfo, isOnline: true);
    }
  }

  void _applyHijriInfo(HijriDateInfo info, {required bool isOnline}) {
    _schedule = _schedule.copyWith(
      hijriDate: info.formattedBn,
      hijriDay: info.day,
      hijriMonth: info.month,
      hijriYear: info.year,
      hijriMonthBn: info.monthNameBn,
      hijriMonthEn: info.monthNameEn,
      hijriDateBn: info.formattedBn,
      hijriDateEn: info.formattedEn,
      isOnlineSynced: isOnline,
    );
    update();
  }

  Future<void> toggleProhibitedAlert() async {
    _isProhibitedAlertOn = !_isProhibitedAlertOn;
    update();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_userKey('prohibited_alert_on', _currentUid), _isProhibitedAlertOn);
  }

  Future<void> setProhibitedBufferMinutes(int minutes) async {
    _prohibitedBufferMinutes = minutes;
    update();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userKey('prohibited_buffer_minutes', _currentUid), _prohibitedBufferMinutes);
  }

  Future<void> _saveLocation([String? uidOverride]) async {
    final uid = uidOverride ?? _currentUid;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey('prayer_location_id', uid), _selectedLocation.id);
    await prefs.setBool(_userKey('prayer_is_hanafi', uid), _isHanafi);
  }
}
