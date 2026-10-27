import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/prayer_time_service.dart';

class ZikirItem {
  final String id;
  final String arabic;
  final String titleBn;
  final String titleEn;
  final String meaningBn;
  final String meaningEn;
  final int defaultTarget;
  final String? benefitBn;
  final bool isCustom;

  const ZikirItem({
    required this.id,
    required this.arabic,
    required this.titleBn,
    required this.titleEn,
    required this.meaningBn,
    required this.meaningEn,
    this.defaultTarget = 33,
    this.benefitBn,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'arabic': arabic,
        'titleBn': titleBn,
        'titleEn': titleEn,
        'meaningBn': meaningBn,
        'meaningEn': meaningEn,
        'defaultTarget': defaultTarget,
        'benefitBn': benefitBn,
        'isCustom': isCustom,
      };

  factory ZikirItem.fromJson(Map<String, dynamic> json) => ZikirItem(
        id: json['id'] as String,
        arabic: json['arabic'] as String? ?? '',
        titleBn: json['titleBn'] as String? ?? '',
        titleEn: json['titleEn'] as String? ?? '',
        meaningBn: json['meaningBn'] as String? ?? '',
        meaningEn: json['meaningEn'] as String? ?? '',
        defaultTarget: json['defaultTarget'] as int? ?? 33,
        benefitBn: json['benefitBn'] as String?,
        isCustom: json['isCustom'] as bool? ?? false,
      );
}

class PrayerTasbihController extends GetxController {
  static PrayerTasbihController get to => Get.find<PrayerTasbihController>();

  // --- Prayer Times State ---
  late BangladeshLocation _selectedLocation;
  BangladeshLocation get selectedLocation => _selectedLocation;

  bool _isHanafi = true;
  bool get isHanafi => _isHanafi;

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
  static const List<ZikirItem> presetZikirs = [
    ZikirItem(
      id: 'subhanallah',
      arabic: 'سُبْحَانَ اللَّهِ',
      titleBn: 'সুবহানাল্লাহ',
      titleEn: 'SubhanAllah',
      meaningBn: 'আল্লাহ পরম পবিত্র ও সকল ত্রুটিমুক্ত',
      meaningEn: 'Glory be to Allah',
      defaultTarget: 33,
      benefitBn: 'নামাজ পরবর্তী মাসনুন আমল। জান্নাতে একটি বৃক্ষ রোপণ করা হয়।',
    ),
    ZikirItem(
      id: 'alhamdulillah',
      arabic: 'الْحَمْدُ لِلَّهِ',
      titleBn: 'আলহামদুলিল্লাহ',
      titleEn: 'Alhamdulillah',
      meaningBn: 'সকল প্রশংসা ও স্তুতি একমাত্র আল্লাহর জন্য',
      meaningEn: 'All praise is due to Allah',
      defaultTarget: 33,
      benefitBn: 'মিজানের পাল্লাকে নেকি দিয়ে ভরপুর করে দেয়।',
    ),
    ZikirItem(
      id: 'allahu_akbar',
      arabic: 'اللَّهُ أَكْبَرُ',
      titleBn: 'আল্লাহু আকবার',
      titleEn: 'Allahu Akbar',
      meaningBn: 'আল্লাহ সর্বশ্রেষ্ঠ ও মহান',
      meaningEn: 'Allah is the Greatest',
      defaultTarget: 34,
      benefitBn: 'আসমান ও জমিনের মধ্যবর্তী স্থান নেকিতে পূর্ণ করে।',
    ),
    ZikirItem(
      id: 'la_ilaha_illallah',
      arabic: 'لَا إِلٰهَ إِلَّا اللَّهُ',
      titleBn: 'লা ইলাহা ইল্লাল্লাহ',
      titleEn: 'La ilaha illallah',
      meaningBn: 'আল্লাহ ছাড়া সত্য কোনো উপাস্য নেই',
      meaningEn: 'There is no god but Allah',
      defaultTarget: 100,
      benefitBn: 'সর্বোত্তম জিকির এবং জান্নাতের চাবিকাঠি।',
    ),
    ZikirItem(
      id: 'astaghfirullah',
      arabic: 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
      titleBn: 'আস্তাগফিরুল্লাহ',
      titleEn: 'Astaghfirullah',
      meaningBn: 'আমি আল্লাহর কাছে ক্ষমা চাই এবং তাঁর দিকে প্রত্যাবর্তন করি',
      meaningEn: 'I seek forgiveness from Allah',
      defaultTarget: 100,
      benefitBn: 'রিজিকে প্রাচুর্য, বিপদমুক্তি ও মনের প্রশান্তি এনে দেয়।',
    ),
    ZikirItem(
      id: 'subhanallahi_wa_bihamdihi',
      arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
      titleBn: 'সুবহানাল্লাহি ওয়া বিহামদিহি',
      titleEn: 'SubhanAllahi wa bihamdihi',
      meaningBn: 'আল্লাহর প্রশংসাসহ পবিত্রতা ঘোষণা করি, মহান আল্লাহ পরম পবিত্র',
      meaningEn: 'Glory be to Allah and all praise is His',
      defaultTarget: 100,
      benefitBn: 'দিনে ১০০ বার পাঠে সমুদ্রের ফেনা পরিমাণ গুনাহ হলেও ক্ষমা হয়।',
    ),
    ZikirItem(
      id: 'la_hawla',
      arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      titleBn: 'লা হাওলা ওয়ালা কুওয়াতা ইল্লা বিল্লাহ',
      titleEn: 'La hawla wa la quwwata illa billah',
      meaningBn: 'আল্লাহর সাহায্য ছাড়া কোনো শক্তি বা ক্ষমতা নেই',
      meaningEn: 'There is no power nor strength except with Allah',
      defaultTarget: 100,
      benefitBn: 'জান্নাতের অমূল্য রত্নভাণ্ডারের অন্যতম।',
    ),
    ZikirItem(
      id: 'durood_sharif',
      arabic: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ',
      titleBn: 'দুরুদ শরীফ',
      titleEn: 'Durood Sharif',
      meaningBn: 'হে আল্লাহ! হযরত মুহাম্মদ (সাঃ) ও তাঁর পরিবারের ওপর রহমত বর্ষণ করুন',
      meaningEn: 'O Allah, send blessings upon Muhammad and his family',
      defaultTarget: 100,
      benefitBn: 'একবার পাঠে ১০টি রহমত, ১০টি গুনাহ মাফ ও ১০টি মর্যাদা বৃদ্ধি।',
    ),
    ZikirItem(
      id: 'hasbunallah',
      arabic: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
      titleBn: 'হাসবুনাল্লাহু ওয়া নি\'মাল ওয়াকিল',
      titleEn: 'Hasbunallahu wa ni\'mal wakeel',
      meaningBn: 'আল্লাহই আমাদের জন্য যথেষ্ট এবং তিনিই সর্বোত্তম কর্মবিধায়ক',
      meaningEn: 'Sufficient for us is Allah, and He is the best Disposer of affairs',
      defaultTarget: 100,
      benefitBn: 'বিপদ-আপদ, মানসিক চাপ ও শত্রুর ভয় থেকে পরম নিরাপত্তা।',
    ),
    ZikirItem(
      id: 'ya_hayyu_ya_qayyum',
      arabic: 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ',
      titleBn: 'ইয়া হাইয়্যু ইয়া কাইয়্যুম',
      titleEn: 'Ya Hayyu Ya Qayyum',
      meaningBn: 'হে চিরঞ্জীব! হে সর্বনিয়ন্তা! আপনার রহমতের আশ্রয় চাই',
      meaningEn: 'O Ever Living, O Sustainer, by Your mercy I seek help',
      defaultTarget: 100,
      benefitBn: 'যে কোনো কঠিন সমস্যা সমাধানের শক্তিশালী দোয়া।',
    ),
  ];

  final List<ZikirItem> _allZikirs = <ZikirItem>[];
  List<ZikirItem> get allZikirs => List.unmodifiable(_allZikirs);

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

  bool _isVibrationEnabled = true;
  bool get isVibrationEnabled => _isVibrationEnabled;

  bool _isSoundEnabled = true;
  bool get isSoundEnabled => _isSoundEnabled;

  // Active tab index (0 = Prayer Times, 1 = Digital Tasbih)
  int _activeTab = 0;
  int get activeTab => _activeTab;

  @override
  void onInit() {
    super.onInit();
    _selectedLocation = BangladeshLocation.defaultLocation;
    _allZikirs.addAll(presetZikirs);
    _selectedZikir = presetZikirs.first;
    _targetCount = _selectedZikir.defaultTarget;

    _recalculatePrayerTimes();
    _loadTasbihData();

    // Start timer to update countdown every minute
    if (!Get.testMode) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _updatePrayerCountdown();
      });
    }
  }

  void stopTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    super.onClose();
  }

  void setActiveTab(int index) {
    _activeTab = index;
    update();
  }

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
    _currentWaqt = _schedule.getCurrentWaqt(now);
    _nextPrayer = _schedule.getNextPrayer(now);

    var targetTime = _nextPrayer!.time;
    if (targetTime.isBefore(now)) {
      // It's after today's Isha, next prayer is tomorrow's Fajr
      targetTime = targetTime.add(const Duration(days: 1));
    }

    final diff = targetTime.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);

    if (hours > 0) {
      _timeUntilNextPrayer = '$hours h $minutes m';
    } else {
      _timeUntilNextPrayer = '$minutes m';
    }
    update();
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

  // --- Tasbih Methods ---
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

    final targetReached = _targetCount > 0 && _currentCount >= _targetCount;

    if (_isVibrationEnabled) {
      if (targetReached) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }

    if (targetReached) {
      _completedCycles++;
      _currentCount = 0; // restart cycle
    }

    _persistTasbihData();
    update();
  }

  void decrement() {
    if (_currentCount > 0) {
      _currentCount--;
      if (_todayTotal > 0) _todayTotal--;
      if (_lifetimeTotal > 0) _lifetimeTotal--;
      if (_isVibrationEnabled) {
        HapticFeedback.selectionClick();
      }
      _persistTasbihData();
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

  // --- Persistence ---
  Future<void> _loadTasbihData() async {
    final prefs = await SharedPreferences.getInstance();

    final locationId = prefs.getString('prayer_location_id') ?? 'dhaka';
    _selectedLocation = BangladeshLocation.divisions.firstWhere(
      (d) => d.id == locationId,
      orElse: () => BangladeshLocation.defaultLocation,
    );
    _isHanafi = prefs.getBool('prayer_is_hanafi') ?? true;
    _recalculatePrayerTimes();

    _isVibrationEnabled = prefs.getBool('tasbih_vibrate') ?? true;
    _isSoundEnabled = prefs.getBool('tasbih_sound') ?? true;
    _lifetimeTotal = prefs.getInt('tasbih_lifetime_total') ?? 0;

    // Check if today's count is for today
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final savedDate = prefs.getString('tasbih_last_date') ?? '';
    if (savedDate == todayKey) {
      _todayTotal = prefs.getInt('tasbih_today_total') ?? 0;
    } else {
      _todayTotal = 0;
      await prefs.setString('tasbih_last_date', todayKey);
      await prefs.setInt('tasbih_today_total', 0);
    }
    update();
  }

  Future<void> _persistTasbihData() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString('tasbih_last_date', todayKey);
    await prefs.setInt('tasbih_today_total', _todayTotal);
    await prefs.setInt('tasbih_lifetime_total', _lifetimeTotal);
  }

  Future<void> _persistSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tasbih_vibrate', _isVibrationEnabled);
    await prefs.setBool('tasbih_sound', _isSoundEnabled);
  }

  Future<void> _saveLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('prayer_location_id', _selectedLocation.id);
    await prefs.setBool('prayer_is_hanafi', _isHanafi);
  }
}
