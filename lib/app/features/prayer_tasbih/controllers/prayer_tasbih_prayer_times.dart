part of 'prayer_tasbih_controller.dart';

extension PrayerTasbihPrayerTimes on PrayerTasbihController {
  // --- Prayer Times Methods ---
  void _recalculatePrayerTimes() {
    final now = DateTime.now();
    _schedule = PrayerTimeCalculator.calculate(
      date: now,
      location: _selectedLocation,
      isHanafi: _isHanafi,
    );
    _updatePrayerCountdown();
  }

  void _updatePrayerCountdown() {
    final now = DateTime.now();
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
