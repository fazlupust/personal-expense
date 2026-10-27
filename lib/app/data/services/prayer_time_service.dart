import 'dart:math' as math;

/// Bangladesh Divisions and locations for accurate prayer times
class BangladeshLocation {
  final String id;
  final String nameEn;
  final String nameBn;
  final double latitude;
  final double longitude;

  const BangladeshLocation({
    required this.id,
    required this.nameEn,
    required this.nameBn,
    required this.latitude,
    required this.longitude,
  });

  static const List<BangladeshLocation> divisions = [
    BangladeshLocation(
      id: 'dhaka',
      nameEn: 'Dhaka',
      nameBn: 'ঢাকা',
      latitude: 23.8103,
      longitude: 90.4125,
    ),
    BangladeshLocation(
      id: 'chittagong',
      nameEn: 'Chittagong',
      nameBn: 'চট্টগ্রাম',
      latitude: 22.3569,
      longitude: 91.7832,
    ),
    BangladeshLocation(
      id: 'sylhet',
      nameEn: 'Sylhet',
      nameBn: 'সিলেট',
      latitude: 24.8949,
      longitude: 91.8687,
    ),
    BangladeshLocation(
      id: 'rajshahi',
      nameEn: 'Rajshahi',
      nameBn: 'রাজশাহী',
      latitude: 24.3745,
      longitude: 88.6042,
    ),
    BangladeshLocation(
      id: 'khulna',
      nameEn: 'Khulna',
      nameBn: 'খুলনা',
      latitude: 22.8456,
      longitude: 89.5403,
    ),
    BangladeshLocation(
      id: 'barishal',
      nameEn: 'Barishal',
      nameBn: 'বরিশাল',
      latitude: 22.7010,
      longitude: 90.3535,
    ),
    BangladeshLocation(
      id: 'rangpur',
      nameEn: 'Rangpur',
      nameBn: 'রংপুর',
      latitude: 25.7439,
      longitude: 89.2752,
    ),
    BangladeshLocation(
      id: 'mymensingh',
      nameEn: 'Mymensingh',
      nameBn: 'ময়মনসিংহ',
      latitude: 24.7471,
      longitude: 90.4203,
    ),
  ];

  static BangladeshLocation get defaultLocation => divisions.first;
}

enum PrayerName {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha,
}

class PrayerTimeItem {
  final PrayerName prayer;
  final String nameEn;
  final String nameBn;
  final String arabicName;
  final DateTime time;
  final bool isWaqt; // true for 5 daily prayers, false for sunrise
  final String icon;

  PrayerTimeItem({
    required this.prayer,
    required this.nameEn,
    required this.nameBn,
    required this.arabicName,
    required this.time,
    required this.isWaqt,
    required this.icon,
  });
}

class DailyPrayerSchedule {
  final DateTime date;
  final BangladeshLocation location;
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final DateTime sehriEnd;
  final DateTime iftar;
  final DateTime tahajjudStart;
  final String hijriDate;

  DailyPrayerSchedule({
    required this.date,
    required this.location,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.sehriEnd,
    required this.iftar,
    required this.tahajjudStart,
    required this.hijriDate,
  });

  List<PrayerTimeItem> get items => [
        PrayerTimeItem(
          prayer: PrayerName.fajr,
          nameEn: 'Fajr',
          nameBn: 'ফজর',
          arabicName: 'الفجر',
          time: fajr,
          isWaqt: true,
          icon: '🌅',
        ),
        PrayerTimeItem(
          prayer: PrayerName.sunrise,
          nameEn: 'Sunrise',
          nameBn: 'সূর্যোদয়',
          arabicName: 'الشروق',
          time: sunrise,
          isWaqt: false,
          icon: '☀️',
        ),
        PrayerTimeItem(
          prayer: PrayerName.dhuhr,
          nameEn: 'Dhuhr',
          nameBn: 'যোহর',
          arabicName: 'الظهر',
          time: dhuhr,
          isWaqt: true,
          icon: '🌞',
        ),
        PrayerTimeItem(
          prayer: PrayerName.asr,
          nameEn: 'Asr',
          nameBn: 'আসর',
          arabicName: 'العصر',
          time: asr,
          isWaqt: true,
          icon: '🌤️',
        ),
        PrayerTimeItem(
          prayer: PrayerName.maghrib,
          nameEn: 'Maghrib (Iftar)',
          nameBn: 'মাগরিব (ইফতার)',
          arabicName: 'المغرب',
          time: maghrib,
          isWaqt: true,
          icon: '🌇',
        ),
        PrayerTimeItem(
          prayer: PrayerName.isha,
          nameEn: 'Isha',
          nameBn: 'এশা',
          arabicName: 'العشاء',
          time: isha,
          isWaqt: true,
          icon: '🌙',
        ),
      ];

  /// Determine current active waqt based on DateTime.now()
  PrayerTimeItem getCurrentWaqt(DateTime now) {
    if (now.isBefore(fajr)) {
      // Before Fajr is Isha / Tahajjud
      return items.firstWhere((i) => i.prayer == PrayerName.isha);
    } else if (now.isBefore(sunrise)) {
      return items.firstWhere((i) => i.prayer == PrayerName.fajr);
    } else if (now.isBefore(dhuhr)) {
      // Between sunrise and dhuhr (Ishraq / Chasht)
      return items.firstWhere((i) => i.prayer == PrayerName.fajr);
    } else if (now.isBefore(asr)) {
      return items.firstWhere((i) => i.prayer == PrayerName.dhuhr);
    } else if (now.isBefore(maghrib)) {
      return items.firstWhere((i) => i.prayer == PrayerName.asr);
    } else if (now.isBefore(isha)) {
      return items.firstWhere((i) => i.prayer == PrayerName.maghrib);
    } else {
      return items.firstWhere((i) => i.prayer == PrayerName.isha);
    }
  }

  /// Get the next upcoming prayer time item
  PrayerTimeItem getNextPrayer(DateTime now) {
    if (now.isBefore(fajr)) {
      return items.firstWhere((i) => i.prayer == PrayerName.fajr);
    } else if (now.isBefore(sunrise)) {
      return items.firstWhere((i) => i.prayer == PrayerName.sunrise);
    } else if (now.isBefore(dhuhr)) {
      return items.firstWhere((i) => i.prayer == PrayerName.dhuhr);
    } else if (now.isBefore(asr)) {
      return items.firstWhere((i) => i.prayer == PrayerName.asr);
    } else if (now.isBefore(maghrib)) {
      return items.firstWhere((i) => i.prayer == PrayerName.maghrib);
    } else if (now.isBefore(isha)) {
      return items.firstWhere((i) => i.prayer == PrayerName.isha);
    } else {
      // Tomorrow Fajr
      return items.firstWhere((i) => i.prayer == PrayerName.fajr);
    }
  }
}

/// Robust Astronomical Prayer Time Calculator tailored for Islamic Foundation Bangladesh
class PrayerTimeCalculator {
  static const double _fajrAngle = 18.0;
  static const double _ishaAngle = 18.0;

  static double _dtr(double d) => d * math.pi / 180.0;
  static double _rtd(double r) => r * 180.0 / math.pi;
  static double _sin(double d) => math.sin(_dtr(d));
  static double _cos(double d) => math.cos(_dtr(d));
  static double _tan(double d) => math.tan(_dtr(d));
  static double _asin(double x) => _rtd(math.asin(x));
  static double _acos(double x) => _rtd(math.acos(x));
  static double _atan(double x) => _rtd(math.atan(x));
  static double _atan2(double y, double x) => _rtd(math.atan2(y, x));
  static double _fixAngle(double a) => a - 360.0 * (a / 360.0).floor();
  static double _fixHour(double a) => a - 24.0 * (a / 24.0).floor();

  static double _julianDate(int year, int month, int day) {
    int y = year;
    int m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floor() + (30.6001 * (m + 1)).floor() + day + b - 1524.5;
  }

  /// Calculates prayer times for a given date, location, and juristic method (Hanafi=true, Shafi=false)
  static DailyPrayerSchedule calculate({
    required DateTime date,
    required BangladeshLocation location,
    bool isHanafi = true,
    double timezone = 6.0,
  }) {
    final jd = _julianDate(date.year, date.month, date.day);
    final d = jd - 2451545.0;

    // Solar coordinates
    final g = _fixAngle(357.529 + 0.98560028 * d);
    final q = _fixAngle(280.459 + 0.98564736 * d);
    final l = _fixAngle(q + 1.915 * _sin(g) + 0.020 * _sin(2 * g));
    final e = 23.439 - 0.00000036 * d;
    final delta = _asin(_sin(e) * _sin(l));
    final ra = _fixAngle(_atan2(_cos(e) * _sin(l), _cos(l))) / 15.0;

    // Equation of time in hours
    double eqt = (q / 15.0) - ra;
    if (eqt > 12.0) eqt -= 24.0;
    if (eqt < -12.0) eqt += 24.0;

    // Midday (Dhuhr)
    final dhuhrHour = _fixHour(12.0 + timezone - (location.longitude / 15.0) - eqt);

    // Sunrise & Sunset / Maghrib
    const alphaSun = -0.8333;
    final cosHSun = (_sin(alphaSun) - _sin(location.latitude) * _sin(delta)) /
        (_cos(location.latitude) * _cos(delta));
    final hSun = _acos(cosHSun.clamp(-1.0, 1.0)) / 15.0;
    final sunriseHour = dhuhrHour - hSun;
    final sunsetHour = dhuhrHour + hSun;

    // Fajr (18 degrees below horizon)
    final cosHFajr = (_sin(-_fajrAngle) - _sin(location.latitude) * _sin(delta)) /
        (_cos(location.latitude) * _cos(delta));
    final hFajr = _acos(cosHFajr.clamp(-1.0, 1.0)) / 15.0;
    final fajrHour = dhuhrHour - hFajr;

    // Isha (18 degrees below horizon)
    final cosHIsha = (_sin(-_ishaAngle) - _sin(location.latitude) * _sin(delta)) /
        (_cos(location.latitude) * _cos(delta));
    final hIsha = _acos(cosHIsha.clamp(-1.0, 1.0)) / 15.0;
    final ishaHour = dhuhrHour + hIsha;

    // Asr: Hanafi (shadow=2) or Shafi (shadow=1)
    final shadow = isHanafi ? 2.0 : 1.0;
    final alphaAsr = _atan(1.0 / (shadow + _tan((location.latitude - delta).abs())));
    final cosHAsr = (_sin(alphaAsr) - _sin(location.latitude) * _sin(delta)) /
        (_cos(location.latitude) * _cos(delta));
    final hAsr = _acos(cosHAsr.clamp(-1.0, 1.0)) / 15.0;
    final asrHour = dhuhrHour + hAsr;

    DateTime toDate(double hourVal) {
      final h = hourVal.floor();
      final m = ((hourVal - h) * 60).round();
      return DateTime(date.year, date.month, date.day, h, m);
    }

    final fajrDate = toDate(fajrHour);
    final sunriseDate = toDate(sunriseHour);
    final dhuhrDate = toDate(dhuhrHour);
    final asrDate = toDate(asrHour);
    final maghribDate = toDate(sunsetHour);
    final ishaDate = toDate(ishaHour);

    // Sehri end (3 minutes before Fajr as Islamic Foundation precaution)
    final sehriDate = fajrDate.subtract(const Duration(minutes: 3));
    final iftarDate = maghribDate;

    // Tahajjud optimal start (last third of the night)
    final nightDuration = fajrDate.difference(maghribDate.subtract(const Duration(days: 1)));
    final tahajjudStart = fajrDate.subtract(Duration(minutes: (nightDuration.inMinutes / 3).round()));

    // Hijri date approximation
    final hijri = _calculateHijri(date);

    return DailyPrayerSchedule(
      date: date,
      location: location,
      fajr: fajrDate,
      sunrise: sunriseDate,
      dhuhr: dhuhrDate,
      asr: asrDate,
      maghrib: maghribDate,
      isha: ishaDate,
      sehriEnd: sehriDate,
      iftar: iftarDate,
      tahajjudStart: tahajjudStart,
      hijriDate: hijri,
    );
  }

  static String _calculateHijri(DateTime date) {
    // Kuwaiti Algorithm for Hijri date
    final jd = _julianDate(date.year, date.month, date.day) + 0.5;
    final l = (jd - 1948440 + 10632).floor();
    final n = ((l - 1) / 10631).floor();
    final l2 = l - 10631 * n + 354;
    final j = ((10985 - l2) / 5316).floor() * ((50 * l2 + 17719) / 17719).floor() +
        (l2 / 5670).floor() * ((43 * l2 + 15238) / 15238).floor();
    final l3 = l2 - ((30 - j) / 15).floor() * ((17719 * j) / 50).floor() -
        (j / 16).floor() * ((15238 * j) / 43).floor() + 29;
    final month = ((24 * l3) / 709).floor();
    final day = l3 - ((709 * month) / 24).floor();
    final year = 30 * n + j - 30;

    const islamicMonthsBn = [
      'মুহাররম',
      'সফর',
      'রবিউল আউয়াল',
      'রবিউস সানি',
      'জমাদিউল আউয়াল',
      'জমাদিউস সানি',
      'রজব',
      'শাবান',
      'রমজান',
      'শাওয়াল',
      'জিলকদ',
      'জিলহজ্জ'
    ];

    final mIdx = (month - 1).clamp(0, 11);
    final mName = islamicMonthsBn[mIdx];
    return '$day $mName $year হিজরি';
  }
}
