import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/auth_service.dart';
import '../../../data/services/prayer_time_service.dart';

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
      id: 'la_ilaha_illallah',
      arabic: 'لَا إِلٰهَ إِلَّا اللَّهُ',
      titleBn: 'লা ইলাহা ইল্লাল্লাহ',
      titleEn: 'La ilaha illallah',
      meaningBn: 'আল্লাহ ছাড়া সত্য কোনো উপাস্য নেই',
      meaningEn: 'There is no god but Allah',
      defaultTarget: 100,
      benefitBn: 'সর্বোত্তম জিকির (আফজালুজ জিকির) এবং জান্নাতের চাবিকাঠি।',
      category: ZikirCategory.prayer,
    ),
    ZikirItem(
      id: 'subhanallahi_wa_bihamdihi',
      arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      titleBn: 'সুবহানাল্লাহি ওয়া বিহামদিহি',
      titleEn: 'SubhanAllahi wa bihamdihi',
      meaningBn: 'আল্লাহর প্রশংসাসহ পবিত্রতা ঘোষণা করি',
      meaningEn: 'Glory be to Allah and all praise is His',
      defaultTarget: 100,
      benefitBn: 'দিনে ১০০ বার পাঠে সমুদ্রের ফেনা পরিমাণ গুনাহ হলেও ক্ষমা করে দেওয়া হয়।',
      category: ZikirCategory.morningEvening,
    ),
    ZikirItem(
      id: 'astaghfirullah',
      arabic: 'أَسْتَغْفِرُ اللَّهَ',
      titleBn: 'আস্তাগফিরুল্লাহ',
      titleEn: 'Astaghfirullah',
      meaningBn: 'আমি আল্লাহর কাছে ক্ষমা প্রার্থনা করছি',
      meaningEn: 'I seek forgiveness from Allah',
      defaultTarget: 100,
      benefitBn: 'রিজিকে প্রাচুর্য, বিপদমুক্তি ও মনের প্রশান্তি এনে দেয়।',
      category: ZikirCategory.forgiveness,
    ),
    ZikirItem(
      id: 'subhanallahi_wa_bihamdihi_azim',
      arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
      titleBn: 'সুবহানাল্লাহি ওয়া বিহামদিহি সুবহানাল্লাহিল আজিম',
      titleEn: 'SubhanAllahi wa bihamdihi SubhanAllahil Azeem',
      meaningBn: 'আল্লাহর প্রশংসাসহ পবিত্রতা ঘোষণা করি, মহান আল্লাহ পরম পবিত্র',
      meaningEn: 'Glory be to Allah and all praise is His, Glory be to Allah the Almighty',
      defaultTarget: 100,
      benefitBn: 'মুখে উচ্চারণে সহজ, মিজানের পাল্লায় অতি ভারী এবং রহমানের কাছে অতি প্রিয়।',
      category: ZikirCategory.morningEvening,
    ),
    ZikirItem(
      id: 'astaghfirullah_wa_atubu_ilaih',
      arabic: 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
      titleBn: 'আস্তাগফিরুল্লাহ ওয়া আতুবু ইলাইহি',
      titleEn: 'Astaghfirullaha wa Atubu Ilayh',
      meaningBn: 'আমি আল্লাহর কাছে ক্ষমা চাই এবং তাঁর দিকে প্রত্যাবর্তন করি',
      meaningEn: 'I seek forgiveness from Allah and repent to Him',
      defaultTarget: 100,
      benefitBn: 'নবীজি (সাঃ) দিনে ৭০ থেকে ১০০ বার এই তাওবা ও ইস্তিগফার পাঠ করতেন।',
      category: ZikirCategory.forgiveness,
    ),
    ZikirItem(
      id: 'subhanallah',
      arabic: 'سُبْحَانَ اللَّهِ',
      titleBn: 'সুবহানাল্লাহ',
      titleEn: 'SubhanAllah',
      meaningBn: 'আল্লাহ পরম পবিত্র ও সকল ত্রুটিমুক্ত',
      meaningEn: 'Glory be to Allah',
      defaultTarget: 33,
      benefitBn: 'নামাজ পরবর্তী মাসনুন আমল। জান্নাতে একটি বৃক্ষ রোপণ করা হয়।',
      category: ZikirCategory.prayer,
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
      category: ZikirCategory.prayer,
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
      category: ZikirCategory.prayer,
    ),
    ZikirItem(
      id: 'ayatul_kursi',
      arabic: 'اللَّهُ لَا إِلٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ',
      titleBn: 'আয়াতুল কুরসী',
      titleEn: 'Ayatul Kursi',
      meaningBn: 'আল্লাহ, তিনি ছাড়া সত্য কোনো উপাস্য নেই, তিনি চিরঞ্জীব ও সর্বসত্তার ধারক',
      meaningEn: 'Allah! There is no deity except Him, the Ever-Living, the Sustainer',
      defaultTarget: 7,
      benefitBn: 'কুরআনের শ্রেষ্ঠ আয়াত। প্রতিটি ফরজ নামাজের পর পাঠে জান্নাত সুনিশ্চিত।',
      category: ZikirCategory.prayer,
    ),
    ZikirItem(
      id: 'four_kalimas',
      arabic: 'سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ وَلَا إِلٰهَ إِلَّا اللَّهُ وَاللَّهُ أَكْبَرُ',
      titleBn: 'চার তাসবীহ (কালেমা তামজিদ)',
      titleEn: 'SubhanAllah wal-Hamdulillah',
      meaningBn: 'আল্লাহ পরম পবিত্র, সকল প্রশংসা আল্লাহর, আল্লাহ ছাড়া সত্য উপাস্য নেই এবং আল্লাহ সর্বশ্রেষ্ঠ',
      meaningEn: 'Glory be to Allah, all praise to Allah, no god but Allah, Allah is the Greatest',
      defaultTarget: 100,
      benefitBn: 'হযরত ইব্রাহিম (আঃ) জান্নাতের বৃক্ষ রোপণের জন্য এই জিকির উপহার দিয়েছিলেন।',
      category: ZikirCategory.prayer,
    ),
    ZikirItem(
      id: 'la_ilaha_wahdahu',
      arabic: 'لَا إِلٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      titleBn: 'লা ইলাহা ইল্লাল্লাহু ওয়াহদাহু',
      titleEn: 'La ilaha illallahu Wahdahu',
      meaningBn: 'আল্লাহ ছাড়া সত্য কোনো উপাস্য নেই, তিনি একক, কোনো শরিক নেই; রাজত্ব ও প্রশংসা একমাত্র তাঁরই...',
      meaningEn: 'There is no god but Allah alone with no partner, to Him belongs dominion and praise...',
      defaultTarget: 100,
      benefitBn: 'দিনে ১০০ বার পাঠে ১০টি গোলাম মুক্ত করার সওয়াব ও ১০০টি গুনাহ মাফ হয়।',
      category: ZikirCategory.prayer,
    ),
    ZikirItem(
      id: 'allahumma_ajirni',
      arabic: 'اللَّهُمَّ أَجِرْنِي مِنَ النَّارِ',
      titleBn: 'জাহান্নাম মুক্তির দোয়া',
      titleEn: 'Allahumma Ajirni Minan Naar',
      meaningBn: 'হে আল্লাহ! আমাকে জাহান্নামের আগুন থেকে রক্ষা করুন',
      meaningEn: 'O Allah, save me from the fire of Hell',
      defaultTarget: 7,
      benefitBn: 'ফজর ও মাগরিবের পর ৭ বার পাঠ করলে জাহান্নাম থেকে মুক্তির পরোয়ানা মেলে।',
      category: ZikirCategory.prayer,
    ),
    ZikirItem(
      id: 'sayyidul_istighfar',
      arabic: 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلٰهَ إِلَّا أَنْتَ خَلَقْتَنِي وَأَنَا عَبْدُكَ',
      titleBn: 'সাইয়্যিদুল ইস্তিগফার',
      titleEn: 'Sayyidul Istighfar',
      meaningBn: 'হে আল্লাহ! আপনি আমার রব, আপনি ছাড়া সত্য কোনো উপাস্য নেই। আপনি আমাকে সৃষ্টি করেছেন...',
      meaningEn: 'O Allah, You are my Lord, there is no deity except You. You created me and I am Your servant',
      defaultTarget: 3,
      benefitBn: 'ক্ষমা প্রার্থনার শ্রেষ্ঠতম দোয়া। সকালে বা সন্ধ্যায় পাঠে জান্নাত প্রাপ্তির সুসংবাদ।',
      category: ZikirCategory.forgiveness,
    ),
    ZikirItem(
      id: 'dua_yunus',
      arabic: 'لَا إِلٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
      titleBn: 'দোয়া ইউনুস (বিপদ মুক্তি)',
      titleEn: 'Dua Yunus',
      meaningBn: 'আপনি ছাড়া সত্য কোনো উপাস্য নেই, আপনি পরম পবিত্র, নিশ্চয় আমি অপরাধীদের অন্তর্ভুক্ত',
      meaningEn: 'There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers',
      defaultTarget: 100,
      benefitBn: 'যেকোনো কঠিন বিপদ, দুশ্চিন্তা ও রোগ-শোক মুক্তির জন্য পরীক্ষিত দোয়া।',
      category: ZikirCategory.forgiveness,
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
      category: ZikirCategory.salawat,
    ),
    ZikirItem(
      id: 'durood_ibrahim',
      arabic: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ',
      titleBn: 'দুরুদে ইব্রাহিম (শ্রেষ্ঠ দুরুদ)',
      titleEn: 'Durood-e-Ibrahim',
      meaningBn: 'হে আল্লাহ! হযরত মুহাম্মদ (সাঃ) ও তাঁর পরিবারের ওপর রহমত বর্ষণ করুন যেমনটি করেছিলেন ইব্রাহিম (আঃ)-এর ওপর...',
      meaningEn: 'O Allah, send blessings upon Muhammad and the family of Muhammad, as You sent blessings upon Ibrahim...',
      defaultTarget: 10,
      benefitBn: 'নামাজের তাশাহহুদে পঠিত সর্বোত্তম ও সর্বাধিক বরকতপূর্ণ দুরুদ।',
      category: ZikirCategory.salawat,
    ),
    ZikirItem(
      id: 'adada_khalqihi',
      arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ عَدَدَ خَلْقِهِ وَرِضَا نَفْسِهِ وَزِنَةَ عَرْشِهِ وَمِدَادَ كَلِمَاتِهِ',
      titleBn: 'কোটি নেকির জিকির (আদাদা খালকিহি)',
      titleEn: 'SubhanAllahi Adada Khalqihi',
      meaningBn: 'আল্লাহর পবিত্রতা ঘোষণা করি তাঁর সৃষ্টির সংখ্যার সমপরিমাণ, তাঁর সন্তুষ্টির সমপরিমাণ, আরশের ওজনের সমপরিমাণ...',
      meaningEn: 'Glory be to Allah and His is the praise, according to the number of His creation...',
      defaultTarget: 3,
      benefitBn: 'সকালে মাত্র ৩ বার পাঠ করলে সারাদিনের সব জিকিরের সমান সওয়াব অর্জিত হয়।',
      category: ZikirCategory.morningEvening,
    ),
    ZikirItem(
      id: 'bismillahillazi',
      arabic: 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ',
      titleBn: 'ক্ষতি ও অনিষ্ট থেকে বাঁচার দোয়া',
      titleEn: 'Bismillahillazi La Yadurru',
      meaningBn: 'আল্লাহর নামে, যাঁর নামের সাথে আসমান ও জমিনের কোনো কিছুই ক্ষতি করতে পারে না, তিনি সর্বশ্রোতা ও সর্বজ্ঞ',
      meaningEn: 'In the Name of Allah, with Whose Name nothing upon earth or in the heavens can cause harm...',
      defaultTarget: 3,
      benefitBn: 'সকালে ও সন্ধ্যায় ৩ বার পাঠ করলে বিষাক্ত প্রাণী বা কোনো অনিষ্ট ক্ষতি করতে পারে না।',
      category: ZikirCategory.morningEvening,
    ),
    ZikirItem(
      id: 'hasbiyallahu',
      arabic: 'حَسْبِيَ اللَّهُ لَا إِلٰهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
      titleBn: 'সকল দুশ্চিন্তা মুক্তির দোয়া',
      titleEn: 'Hasbiyallahu La Ilaha Illa Hu',
      meaningBn: 'আল্লাহই আমার জন্য যথেষ্ট, তিনি ছাড়া সত্য উপাস্য নেই, তাঁরই ওপর ভরসা করি এবং তিনি মহা আরশের মালিক',
      meaningEn: 'Sufficient for me is Allah; there is no deity except Him. On Him I have relied, Lord of the Great Throne',
      defaultTarget: 7,
      benefitBn: 'সকাল ও সন্ধ্যায় ৭ বার পাঠ করলে দুনিয়া ও আখিরাতের সকল দুশ্চিন্তার জন্য আল্লাহই যথেষ্ট হয়ে যান।',
      category: ZikirCategory.morningEvening,
    ),
    ZikirItem(
      id: 'ask_jannah',
      arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْجَنَّةَ',
      titleBn: 'জান্নাত প্রার্থনার দোয়া',
      titleEn: 'Allahumma Inni As\'alukal Jannah',
      meaningBn: 'হে আল্লাহ! আমি আপনার নিকট জান্নাতুল ফিরদাউস প্রার্থনা করছি',
      meaningEn: 'O Allah, I ask You for Paradise',
      defaultTarget: 7,
      benefitBn: 'প্রতিদিন পাঠ করলে জান্নাত নিজেই আল্লাহর কাছে সেই বান্দার জন্য সুপারিশ করে।',
      category: ZikirCategory.morningEvening,
    ),
    ZikirItem(
      id: 'kalima_tayyibah',
      arabic: 'لَا إِلٰهَ إِلَّا اللَّهُ مُحَمَّدٌ رَسُولُ اللَّهِ',
      titleBn: 'কালেমা তাইয়্যেবা',
      titleEn: 'Kalima Tayyibah',
      meaningBn: 'আল্লাহ ছাড়া সত্য কোনো উপাস্য নেই, মুহাম্মদ (সাঃ) আল্লাহর রাসুল',
      meaningEn: 'There is no god but Allah, Muhammad is the Messenger of Allah',
      defaultTarget: 100,
      benefitBn: 'ঈমানের মূল ভিত্তি ও সর্বোত্তম জিকির।',
      category: ZikirCategory.dua,
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
      category: ZikirCategory.dua,
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
      category: ZikirCategory.dua,
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
      category: ZikirCategory.dua,
    ),
    ZikirItem(
      id: 'rabbana_atina',
      arabic: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      titleBn: 'রাব্বানা আতিনা ফিদ দুনিয়া',
      titleEn: 'Rabbana Atina Fid Dunya',
      meaningBn: 'হে আমাদের রব! আমাদের দুনিয়াতে কল্যাণ দিন, আখিরাতেও কল্যাণ দিন এবং আগুনের শাস্তি থেকে বাঁচান',
      meaningEn: 'Our Lord, give us in this world good and in the Hereafter good, and save us from the fire',
      defaultTarget: 33,
      benefitBn: 'রাসুলুল্লাহ (সাঃ) এই দোয়াটি সবচেয়ে বেশি পাঠ করতেন।',
      category: ZikirCategory.dua,
    ),
    ZikirItem(
      id: 'rabbish_rahli',
      arabic: 'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي وَاحْلُلْ عُقْدَةً مِنْ لِسَانِي',
      titleBn: 'রাব্বিশ রাহলি সাদরি (সহজ হওয়ার দোয়া)',
      titleEn: 'Rabbish Rahli Sadri',
      meaningBn: 'হে আমার পালনকর্তা! আমার বক্ষ প্রশস্ত করে দিন, কাজ সহজ করে দিন এবং জিহ্বার জড়তা দূর করে দিন',
      meaningEn: 'My Lord, expand for me my breast, ease for me my task, and untie the knot from my tongue',
      defaultTarget: 33,
      benefitBn: 'পরীক্ষা, ইন্টারভিউ বা কঠিন কাজের পূর্বে মানসিক স্থিরতা ও সফলতার দোয়া।',
      category: ZikirCategory.dua,
    ),
    ZikirItem(
      id: 'dua_for_parents',
      arabic: 'رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
      titleBn: 'পিতা-মাতার জন্য দোয়া',
      titleEn: 'Dua for Parents',
      meaningBn: 'হে আমার প্রতিপালক! তাঁদের (পিতা-মাতা) উভয়ের প্রতি দয়া করুন, যেভাবে শৈশবে তাঁরা আমাকে লালন-পালন করেছিলেন',
      meaningEn: 'My Lord, have mercy upon them as they brought me up when I was small',
      defaultTarget: 33,
      benefitBn: 'পিতা-মাতার জীবিত বা মৃত অবস্থায় তাঁদের জন্য শ্রেষ্ঠ কুরআনিক দোয়া।',
      category: ZikirCategory.dua,
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

  // --- Per-Zikir Recitation Counters & History ---
  // zikirId -> lifetime count
  final Map<String, int> _zikirLifetimeCounts = <String, int>{};
  Map<String, int> get zikirLifetimeCounts => Map.unmodifiable(_zikirLifetimeCounts);

  // yyyy-MM-dd -> (zikirId -> count on that date)
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
    _bindAuth();

    // Start timer to update countdown every minute
    if (!Get.testMode) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _updatePrayerCountdown();
      });
    }
  }

  void _bindAuth() {
    if (Get.isRegistered<AuthService>()) {
      final auth = Get.find<AuthService>();
      ever(auth.firebaseUser, (user) {
        if (user != null) {
          _loadTasbihData(user.uid);
          _syncFromFirestore(user.uid);
        } else {
          _resetUserScopedData();
        }
      });
      if (auth.currentUid != null && auth.currentUid!.isNotEmpty) {
        _syncFromFirestore(auth.currentUid!);
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

    // Track per-zikir recitations
    final zId = _selectedZikir.id;
    _zikirLifetimeCounts[zId] = (_zikirLifetimeCounts[zId] ?? 0) + 1;
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dayMap = _zikirDailyCounts.putIfAbsent(todayKey, () => <String, int>{});
    dayMap[zId] = (dayMap[zId] ?? 0) + 1;

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

  // --- Firestore Sync & User-Isolation ---
  Timer? _firestoreDebounceTimer;

  void _scheduleFirestoreSync() {
    final uid = _currentUid;
    if (uid.isEmpty) return;
    _firestoreDebounceTimer?.cancel();
    _firestoreDebounceTimer = Timer(const Duration(milliseconds: 600), () {
      _flushToFirestore(uid);
    });
  }

  Future<void> flushNowForTesting([String? uidOverride]) async {
    final uid = uidOverride ?? _currentUid;
    if (uid.isNotEmpty) {
      await _flushToFirestore(uid);
    }
  }

  Future<void> _flushToFirestore(String uid) async {
    if (uid.isEmpty) {
      debugPrint('[TasbihFirestore] Skip sync: No user UID found. Saved locally in SharedPreferences.');
      return;
    }
    try {
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final dayCounts = _zikirDailyCounts[todayKey] ?? <String, int>{};

      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      // 1. Day-wise and zikir-wise document: users/{uid}/tasbih_daily/{todayKey}
      final dayDoc = db
          .collection('users')
          .doc(uid)
          .collection('tasbih_daily')
          .doc(todayKey);

      batch.set(
        dayDoc,
        {
          'user_id': uid,
          'date': todayKey,
          'counts': Map<String, dynamic>.from(dayCounts),
          'day_total': _todayTotal,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 2. Summary document with lifetime total and zikir-wise totals
      final summaryDoc = db
          .collection('users')
          .doc(uid)
          .collection('tasbih_summary')
          .doc('summary');

      batch.set(
        summaryDoc,
        {
          'user_id': uid,
          'lifetime_total': _lifetimeTotal,
          'today_total': _todayTotal,
          'last_date': todayKey,
          'zikir_lifetime_counts': Map<String, dynamic>.from(_zikirLifetimeCounts),
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      debugPrint('[TasbihFirestore] Synced to Firestore for user: $uid (date: $todayKey, counts: $dayCounts)');
    } catch (e) {
      debugPrint('[TasbihFirestore] Error syncing to Firestore: $e');
    }
  }

  Future<void> _syncFromFirestore(String uid) async {
    if (uid.isEmpty) return;
    try {
      final db = FirebaseFirestore.instance;

      // 1. Fetch summary document
      final summaryDoc = await db
          .collection('users')
          .doc(uid)
          .collection('tasbih_summary')
          .doc('summary')
          .get();

      if (summaryDoc.exists && summaryDoc.data() != null) {
        final data = summaryDoc.data()!;
        final remoteLifetime = (data['lifetime_total'] as num?)?.toInt() ?? 0;
        if (remoteLifetime > _lifetimeTotal) {
          _lifetimeTotal = remoteLifetime;
        }

        final remoteZikirCounts = data['zikir_lifetime_counts'] as Map<String, dynamic>?;
        if (remoteZikirCounts != null) {
          remoteZikirCounts.forEach((k, v) {
            final cnt = (v as num).toInt();
            _zikirLifetimeCounts[k] = max(_zikirLifetimeCounts[k] ?? 0, cnt);
          });
        }
      }

      // 2. Fetch daily documents (limit to recent 90 days for fast loading)
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final dailySnap = await db
          .collection('users')
          .doc(uid)
          .collection('tasbih_daily')
          .limit(90)
          .get();

      for (final doc in dailySnap.docs) {
        final dateKey = doc.id;
        final counts = doc.data()['counts'] as Map<String, dynamic>?;
        if (counts != null) {
          final dayMap = _zikirDailyCounts.putIfAbsent(dateKey, () => <String, int>{});
          counts.forEach((k, v) {
            final cnt = (v as num).toInt();
            dayMap[k] = max(dayMap[k] ?? 0, cnt);
          });
        }
      }

      // Re-evaluate today's total from day map
      final todayMap = _zikirDailyCounts[todayKey];
      if (todayMap != null && todayMap.isNotEmpty) {
        int sumToday = 0;
        todayMap.forEach((_, c) => sumToday += c);
        if (sumToday > _todayTotal) {
          _todayTotal = sumToday;
        }
      }

      await _persistTasbihData(uid);
      update();
      debugPrint('[TasbihFirestore] Loaded from Firestore for user: $uid (today: $_todayTotal, lifetime: $_lifetimeTotal)');
    } catch (e) {
      debugPrint('[TasbihFirestore] Error fetching from Firestore: $e');
    }
  }

  // --- Persistence ---
  Future<void> _loadTasbihData([String? uidOverride]) async {
    final uid = uidOverride ?? _currentUid;
    final prefs = await SharedPreferences.getInstance();

    _currentCount = 0;
    _completedCycles = 0;
    _todayTotal = 0;
    _lifetimeTotal = 0;
    _zikirLifetimeCounts.clear();
    _zikirDailyCounts.clear();

    final locationId = prefs.getString(_userKey('prayer_location_id', uid)) ?? 'dhaka';
    _selectedLocation = BangladeshLocation.findById(locationId);
    _isHanafi = prefs.getBool(_userKey('prayer_is_hanafi', uid)) ?? true;
    _recalculatePrayerTimes();

    _isVibrationEnabled = prefs.getBool(_userKey('tasbih_vibrate', uid)) ?? true;
    _isSoundEnabled = prefs.getBool(_userKey('tasbih_sound', uid)) ?? true;
    _isCountHidden = prefs.getBool(_userKey('tasbih_hide_count', uid)) ?? false;
    _isZikirCardHidden = prefs.getBool(_userKey('tasbih_hide_zikir_card', uid)) ?? true;
    _isProhibitedAlertOn = prefs.getBool(_userKey('prohibited_alert_on', uid)) ?? true;
    _prohibitedBufferMinutes = prefs.getInt(_userKey('prohibited_buffer_minutes', uid)) ?? 15;

    // Backward compatibility: If user-keyed is not found and un-keyed exists, migrate
    if (uid.isNotEmpty && !prefs.containsKey(_userKey('tasbih_lifetime_total', uid))) {
      final oldLifetime = prefs.getInt('tasbih_lifetime_total');
      if (oldLifetime != null && oldLifetime > 0) {
        _lifetimeTotal = oldLifetime;
        final oldDaily = prefs.getString('tasbih_zikir_daily_counts');
        if (oldDaily != null) {
          try {
            final decoded = jsonDecode(oldDaily) as Map<String, dynamic>;
            decoded.forEach((dateKey, map) {
              if (map is Map) {
                final inner = <String, int>{};
                map.forEach((k, v) => inner[k.toString()] = (v as num).toInt());
                _zikirDailyCounts[dateKey] = inner;
              }
            });
          } catch (_) {}
        }
        final oldLifetimeZikirs = prefs.getString('tasbih_zikir_lifetime_counts');
        if (oldLifetimeZikirs != null) {
          try {
            final decoded = jsonDecode(oldLifetimeZikirs) as Map<String, dynamic>;
            decoded.forEach((k, v) => _zikirLifetimeCounts[k] = (v as num).toInt());
          } catch (_) {}
        }
        await _persistTasbihData(uid);
        // Remove legacy un-keyed prefs so they never bleed to other accounts
        await prefs.remove('tasbih_lifetime_total');
        await prefs.remove('tasbih_zikir_daily_counts');
        await prefs.remove('tasbih_zikir_lifetime_counts');
        await prefs.remove('tasbih_today_total');
        await prefs.remove('tasbih_last_date');
        _scheduleFirestoreSync();
      } else {
        _lifetimeTotal = 0;
      }
    } else {
      _lifetimeTotal = prefs.getInt(_userKey('tasbih_lifetime_total', uid)) ?? 0;
    }

    // Load per-zikir lifetime counts
    final lifetimeJsonStr = prefs.getString(_userKey('tasbih_zikir_lifetime_counts', uid));
    if (lifetimeJsonStr != null) {
      try {
        final decoded = jsonDecode(lifetimeJsonStr) as Map<String, dynamic>;
        _zikirLifetimeCounts.clear();
        decoded.forEach((k, v) => _zikirLifetimeCounts[k] = (v as num).toInt());
      } catch (_) {}
    } else if (uid.isNotEmpty && !prefs.containsKey(_userKey('tasbih_lifetime_total', uid))) {
      // migrated above
    } else {
      _zikirLifetimeCounts.clear();
    }

    // Load per-zikir daily counts
    final dailyJsonStr = prefs.getString(_userKey('tasbih_zikir_daily_counts', uid));
    if (dailyJsonStr != null) {
      try {
        final decoded = jsonDecode(dailyJsonStr) as Map<String, dynamic>;
        _zikirDailyCounts.clear();
        decoded.forEach((dateKey, map) {
          if (map is Map) {
            final inner = <String, int>{};
            map.forEach((k, v) => inner[k.toString()] = (v as num).toInt());
            _zikirDailyCounts[dateKey] = inner;
          }
        });
      } catch (_) {}
    } else if (uid.isNotEmpty && !prefs.containsKey(_userKey('tasbih_lifetime_total', uid))) {
      // migrated above
    } else {
      _zikirDailyCounts.clear();
    }

    // Check if today's count is for today
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final savedDate = prefs.getString(_userKey('tasbih_last_date', uid)) ?? '';
    if (savedDate == todayKey) {
      _todayTotal = prefs.getInt(_userKey('tasbih_today_total', uid)) ?? 0;
    } else {
      _todayTotal = 0;
      await prefs.setString(_userKey('tasbih_last_date', uid), todayKey);
      await prefs.setInt(_userKey('tasbih_today_total', uid), 0);
    }
    update();
  }

  Future<void> _persistTasbihData([String? uidOverride]) async {
    final uid = uidOverride ?? _currentUid;
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final snapToday = _todayTotal;
    final snapLife = _lifetimeTotal;
    final snapLifetimeZikirs = jsonEncode(_zikirLifetimeCounts);
    final snapDailyZikirs = jsonEncode(_zikirDailyCounts);

    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;

    await prefs.setString(_userKey('tasbih_last_date', uid), todayKey);
    await prefs.setInt(_userKey('tasbih_today_total', uid), snapToday);
    await prefs.setInt(_userKey('tasbih_lifetime_total', uid), snapLife);
    await prefs.setString(_userKey('tasbih_zikir_lifetime_counts', uid), snapLifetimeZikirs);
    await prefs.setString(_userKey('tasbih_zikir_daily_counts', uid), snapDailyZikirs);
  }

  Future<void> _persistSettings([String? uidOverride]) async {
    final uid = uidOverride ?? _currentUid;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setBool(_userKey('tasbih_vibrate', uid), _isVibrationEnabled);
    await prefs.setBool(_userKey('tasbih_sound', uid), _isSoundEnabled);
    await prefs.setBool(_userKey('tasbih_hide_count', uid), _isCountHidden);
    await prefs.setBool(_userKey('tasbih_hide_zikir_card', uid), _isZikirCardHidden);
  }

  Future<void> _saveLocation([String? uidOverride]) async {
    final uid = uidOverride ?? _currentUid;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey('prayer_location_id', uid), _selectedLocation.id);
    await prefs.setBool(_userKey('prayer_is_hanafi', uid), _isHanafi);
  }
}
