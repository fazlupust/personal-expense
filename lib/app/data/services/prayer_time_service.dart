import 'dart:math' as math;
import 'package:intl/intl.dart';

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

  static const List<BangladeshLocation> districts = [
    BangladeshLocation(
      id: 'pabna',
      nameEn: 'Pabna',
      nameBn: 'পাবনা',
      latitude: 24.0064,
      longitude: 89.2372,
    ),
    BangladeshLocation(
      id: 'sirajganj',
      nameEn: 'Sirajganj',
      nameBn: 'সিরাজগঞ্জ',
      latitude: 24.4534,
      longitude: 89.7008,
    ),
    BangladeshLocation(
      id: 'naogaon',
      nameEn: 'Naogaon',
      nameBn: 'নওগাঁ',
      latitude: 24.8103,
      longitude: 88.9414,
    ),
    BangladeshLocation(
      id: 'chapainawabganj',
      nameEn: 'Chapainawabganj',
      nameBn: 'চাঁপাইনবাবগঞ্জ',
      latitude: 24.5965,
      longitude: 88.2775,
    ),
    BangladeshLocation(
      id: 'bogura',
      nameEn: 'Bogura',
      nameBn: 'বগুড়া',
      latitude: 24.8465,
      longitude: 89.3777,
    ),
    BangladeshLocation(
      id: 'natore',
      nameEn: 'Natore',
      nameBn: 'নাটোর',
      latitude: 24.4102,
      longitude: 88.9796,
    ),
    BangladeshLocation(
      id: 'kushtia',
      nameEn: 'Kushtia',
      nameBn: 'কুষ্টিয়া',
      latitude: 23.9013,
      longitude: 89.1205,
    ),
    BangladeshLocation(
      id: 'jashore',
      nameEn: 'Jashore',
      nameBn: 'যশোর',
      latitude: 23.1664,
      longitude: 89.2081,
    ),
    BangladeshLocation(
      id: 'cumilla',
      nameEn: 'Cumilla',
      nameBn: 'কুমিল্লা',
      latitude: 23.4682,
      longitude: 91.1788,
    ),
    BangladeshLocation(
      id: 'gazipur',
      nameEn: 'Gazipur',
      nameBn: 'গাজীপুর',
      latitude: 23.9999,
      longitude: 90.4203,
    ),
    BangladeshLocation(
      id: 'narayanganj',
      nameEn: 'Narayanganj',
      nameBn: 'নারায়ণগঞ্জ',
      latitude: 23.6238,
      longitude: 90.5000,
    ),
    BangladeshLocation(
      id: 'tangail',
      nameEn: 'Tangail',
      nameBn: 'টাঙ্গাইল',
      latitude: 24.2513,
      longitude: 89.9167,
    ),
    BangladeshLocation(
      id: 'dinajpur',
      nameEn: 'Dinajpur',
      nameBn: 'দিনাজপুর',
      latitude: 25.6217,
      longitude: 88.6355,
    ),
    BangladeshLocation(
      id: 'coxs_bazar',
      nameEn: 'Cox\'s Bazar',
      nameBn: 'কক্সবাজার',
      latitude: 21.4272,
      longitude: 92.0058,
    ),
    BangladeshLocation(
      id: 'brahmanbaria',
      nameEn: 'Brahmanbaria',
      nameBn: 'ব্রাহ্মণবাড়িয়া',
      latitude: 23.9571,
      longitude: 91.1119,
    ),
    BangladeshLocation(
      id: 'noakhali',
      nameEn: 'Noakhali',
      nameBn: 'নোয়াখালী',
      latitude: 22.8696,
      longitude: 91.0998,
    ),
    BangladeshLocation(
      id: 'feni',
      nameEn: 'Feni',
      nameBn: 'ফেনী',
      latitude: 23.0159,
      longitude: 91.3976,
    ),
  ];

  static List<BangladeshLocation> get allLocations => [
        ...divisions,
        ...districts,
      ];

  static BangladeshLocation get defaultLocation => divisions.first;

  static BangladeshLocation findById(String id) {
    return allLocations.firstWhere(
      (d) => d.id == id,
      orElse: () => defaultLocation,
    );
  }
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
  final DateTime? endTime;
  final bool isWaqt; // true for 5 daily prayers, false for sunrise
  final String icon;

  PrayerTimeItem({
    required this.prayer,
    required this.nameEn,
    required this.nameBn,
    required this.arabicName,
    required this.time,
    this.endTime,
    required this.isWaqt,
    required this.icon,
  });

  /// Formatted time span (e.g. "5:03 AM – 6:18 AM" or "6:18 AM")
  String formatRange({String format = 'h:mm a'}) {
    final startStr = DateFormat(format).format(time);
    if (endTime != null) {
      final endStr = DateFormat(format).format(endTime!);
      return '$startStr – $endStr';
    }
    return startStr;
  }
}

/// Prohibited / Haram times for performing Salah
class ProhibitedTimeItem {
  final String id;
  final String nameEn;
  final String nameBn;
  final String arabicName;
  final DateTime start;
  final DateTime end;
  final String icon;
  final String noteBn;
  final String noteEn;
  final int bufferMinutes;
  final bool isCautionary;

  const ProhibitedTimeItem({
    required this.id,
    required this.nameEn,
    required this.nameBn,
    required this.arabicName,
    required this.start,
    required this.end,
    required this.icon,
    required this.noteBn,
    required this.noteEn,
    this.bufferMinutes = 15,
    this.isCautionary = true,
  });

  /// True if now falls in this prohibited window
  bool contains(DateTime now) => !now.isBefore(start) && now.isBefore(end);

  String formatRange({String format = 'h:mm a'}) {
    final s = DateFormat(format).format(start);
    final e = DateFormat(format).format(end);
    return '$s – $e';
  }
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
          endTime: sunrise,
          isWaqt: true,
          icon: '🌅',
        ),
        PrayerTimeItem(
          prayer: PrayerName.sunrise,
          nameEn: 'Sunrise',
          nameBn: 'সূর্যোদয়',
          arabicName: 'الشروق',
          time: sunrise,
          endTime: null,
          isWaqt: false,
          icon: '☀️',
        ),
        PrayerTimeItem(
          prayer: PrayerName.dhuhr,
          nameEn: 'Dhuhr',
          nameBn: 'যোহর',
          arabicName: 'الظهر',
          time: dhuhr,
          endTime: asr,
          isWaqt: true,
          icon: '🌞',
        ),
        PrayerTimeItem(
          prayer: PrayerName.asr,
          nameEn: 'Asr',
          nameBn: 'আসর',
          arabicName: 'العصر',
          time: asr,
          endTime: maghrib,
          isWaqt: true,
          icon: '🌤️',
        ),
        PrayerTimeItem(
          prayer: PrayerName.maghrib,
          nameEn: 'Maghrib (Iftar)',
          nameBn: 'মাগরিব (ইফতার)',
          arabicName: 'المغرب',
          time: maghrib,
          endTime: isha,
          isWaqt: true,
          icon: '🌇',
        ),
        PrayerTimeItem(
          prayer: PrayerName.isha,
          nameEn: 'Isha',
          nameBn: 'এশা',
          arabicName: 'العشاء',
          time: isha,
          endTime: fajr.add(const Duration(days: 1)),
          isWaqt: true,
          icon: '🌙',
        ),
      ];

  /// Determine current active waqt based on DateTime.now()
  PrayerTimeItem getCurrentWaqt(DateTime now) {
    if (now.isBefore(fajr)) {
      // Before Fajr is Isha / Tahajjud
      final ishaItem = items.firstWhere((i) => i.prayer == PrayerName.isha);
      return PrayerTimeItem(
        prayer: ishaItem.prayer,
        nameEn: ishaItem.nameEn,
        nameBn: ishaItem.nameBn,
        arabicName: ishaItem.arabicName,
        time: isha.subtract(const Duration(days: 1)),
        endTime: fajr,
        isWaqt: true,
        icon: ishaItem.icon,
      );
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

  /// 3 Prohibited / Haram times for performing Salah (Sahih Muslim: 831)
  /// Note: These times are astronomical and vary every day based on the solar position.
  /// Islamic scholars and Islamic Foundation Bangladesh define them as cautionary windows (15–20 minutes).
  List<ProhibitedTimeItem> getProhibitedTimes({int bufferMinutes = 15}) => [
        ProhibitedTimeItem(
          id: 'sunrise',
          nameEn: 'At Sunrise',
          nameBn: 'সূর্যোদয়ের সময়',
          arabicName: 'عند شروق الشمس',
          start: sunrise,
          end: sunrise.add(Duration(minutes: bufferMinutes)),
          icon: '🌅',
          bufferMinutes: bufferMinutes,
          noteBn: 'প্রতিদিন পরিবর্তনশীল: সূর্যোদয় থেকে $bufferMinutes মিনিট (ইশরাক শুরুর পূর্ব মুহূর্ত)',
          noteEn: 'Varies daily: from sunrise until $bufferMinutes min after (before Ishraq)',
        ),
        ProhibitedTimeItem(
          id: 'zawal',
          nameEn: 'At Midday (Zawal)',
          nameBn: 'ঠিক দ্বিপ্রহরের সময় (যাওয়াল)',
          arabicName: 'عند استواء الشمس',
          start: dhuhr.subtract(Duration(minutes: bufferMinutes)),
          end: dhuhr,
          icon: '☀️',
          bufferMinutes: bufferMinutes,
          noteBn: 'প্রতিদিন পরিবর্তনশীল: সূর্য মাথার ঠিক উপরে থাকার সময় (যোহরের ওয়াক্তের আগের $bufferMinutes মিনিট)',
          noteEn: 'Varies daily: when sun is at zenith ($bufferMinutes min before Dhuhr)',
        ),
        ProhibitedTimeItem(
          id: 'sunset',
          nameEn: 'At Sunset',
          nameBn: 'সূর্যাস্তের সময়',
          arabicName: 'عند غروب الشمس',
          start: maghrib.subtract(Duration(minutes: bufferMinutes)),
          end: maghrib,
          icon: '🌇',
          bufferMinutes: bufferMinutes,
          noteBn: 'প্রতিদিন পরিবর্তনশীল: সূর্যাস্তের পূর্ববর্তী $bufferMinutes মিনিট (মাগরিব ওয়াক্ত শুরুর পূর্ব মুহূর্ত)',
          noteEn: 'Varies daily: $bufferMinutes min before sunset (until Maghrib starts)',
        ),
      ];

  List<ProhibitedTimeItem> get prohibitedTimes => getProhibitedTimes();

  /// Returns the active prohibited time item if now falls into one, or null
  ProhibitedTimeItem? getActiveProhibitedTime(DateTime now, {int bufferMinutes = 15}) {
    for (final item in getProhibitedTimes(bufferMinutes: bufferMinutes)) {
      if (item.contains(now)) return item;
    }
    return null;
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

  /// Formats remaining time until next prayer accurately without ever displaying '0 m' or '0 s'.
  /// Handles hours, minutes, seconds countdown (under 1 min), and transitions cleanly.
  static String formatRemainingTime(Duration diff) {
    if (diff.isNegative || diff.inSeconds <= 0) {
      return '< 1 m';
    }
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    final seconds = diff.inSeconds.remainder(60);

    if (hours > 0) {
      return minutes > 0 ? '$hours h $minutes m' : '$hours h';
    } else if (minutes > 0) {
      return '$minutes m';
    } else if (seconds > 0) {
      return '$seconds s';
    } else {
      return '< 1 m';
    }
  }
}

