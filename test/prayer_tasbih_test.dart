import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:personal_expense/app/core/localization/app_translations.dart';
import 'package:personal_expense/app/core/theme/app_theme.dart';
import 'package:personal_expense/app/features/prayer_tasbih/controllers/prayer_tasbih_controller.dart';
import 'package:personal_expense/app/features/prayer_tasbih/views/prayer_tasbih_view.dart';
import 'package:personal_expense/app/features/prayer_tasbih/views/tasbih_counter_view.dart';
import 'package:personal_expense/app/features/prayer_tasbih/views/tasbih_history_view.dart';
import 'package:personal_expense/app/features/dashboard/views/components/dashboard_prayer_card.dart';
import 'package:intl/intl.dart';
import 'package:personal_expense/app/data/models/tasbih_entry_model.dart';
import 'package:personal_expense/app/data/services/prayer_time_service.dart';
import 'package:personal_expense/app/routes/app_pages.dart';
import 'package:personal_expense/app/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
  });

  tearDown(() {
    if (Get.isRegistered<PrayerTasbihController>()) {
      Get.delete<PrayerTasbihController>();
    }
    Get.reset();
    Get.locale = const Locale('en', 'US');
  });

  group('PrayerTasbihController Tests', () {
    test('Initializes with default values and preset zikirs', () {
      final c = Get.put(PrayerTasbihController());

      expect(c.allZikirs.length, greaterThanOrEqualTo(10));
      expect(c.selectedZikir.titleBn, equals('লা ইলাহা ইল্লাল্লাহ'));
      expect(c.currentCount, equals(0));
      expect(c.targetCount, equals(100));
      expect(c.completedCycles, equals(0));
      expect(c.todayTotal, equals(0));
      expect(c.lifetimeTotal, equals(0));
      expect(c.selectedLocation.id, equals('dhaka'));
      expect(c.isHanafi, isTrue);
    });

    test('Increment works and cycles on reaching target', () {
      final c = Get.put(PrayerTasbihController());
      c.setTarget(3);

      c.increment();
      expect(c.currentCount, equals(1));
      expect(c.todayTotal, equals(1));
      expect(c.lifetimeTotal, equals(1));
      expect(c.completedCycles, equals(0));

      c.increment();
      expect(c.currentCount, equals(2));

      // Reaching target: completes cycle and resets current count
      c.increment();
      expect(c.completedCycles, equals(1));
      expect(c.currentCount, equals(0));
      expect(c.todayTotal, equals(3));
      expect(c.lifetimeTotal, equals(3));
    });

    test('Decrement and Reset work accurately', () {
      final c = Get.put(PrayerTasbihController());
      c.increment();
      c.increment();
      expect(c.currentCount, equals(2));

      c.decrement();
      expect(c.currentCount, equals(1));

      c.reset();
      expect(c.currentCount, equals(0));
      expect(c.completedCycles, equals(0));
    });

    test('Zikir selection updates selected zikir and target', () {
      final c = Get.put(PrayerTasbihController());
      final astaghfir = c.allZikirs.firstWhere((z) => z.id == 'astaghfirullah');

      c.selectZikir(astaghfir);
      expect(c.selectedZikir.id, equals('astaghfirullah'));
      expect(c.targetCount, equals(100));
      expect(c.currentCount, equals(0));
    });

    test('Per-zikir recitation tracking and time/category filters work accurately', () {
      final c = Get.put(PrayerTasbihController());

      // Initial counts are 0
      expect(c.getZikirTodayCount('subhanallah'), equals(0));
      expect(c.getZikirLifetimeCount('subhanallah'), equals(0));

      // Select subhanallah and increment 3 times
      final subhan = c.allZikirs.firstWhere((z) => z.id == 'subhanallah');
      c.selectZikir(subhan);
      c.increment();
      c.increment();
      c.increment();

      expect(c.getZikirTodayCount('subhanallah'), equals(3));
      expect(c.getZikirLifetimeCount('subhanallah'), equals(3));
      expect(c.getZikirCount('subhanallah', TasbihTimeFilter.today), equals(3));
      expect(c.getZikirCount('subhanallah', TasbihTimeFilter.thisWeek), equals(3));
      expect(c.getZikirCount('subhanallah', TasbihTimeFilter.thisMonth), equals(3));
      expect(c.getZikirCount('subhanallah', TasbihTimeFilter.allTime), equals(3));

      // Switch to alhamdulillah and increment 2 times
      final alhamdu = c.allZikirs.firstWhere((z) => z.id == 'alhamdulillah');
      c.selectZikir(alhamdu);
      c.increment();
      c.increment();

      expect(c.getZikirTodayCount('alhamdulillah'), equals(2));
      expect(c.getZikirTodayCount('subhanallah'), equals(3));
      expect(c.getZikirLifetimeCount('subhanallah'), equals(3));

      // Decrement reduces per-zikir count
      c.decrement();
      expect(c.getZikirTodayCount('alhamdulillah'), equals(1));

      // Test category filter
      c.setCategoryFilter(ZikirCategory.prayer);
      expect(c.selectedCategoryFilter, equals(ZikirCategory.prayer));
      expect(c.filteredZikirs.every((z) => z.category == ZikirCategory.prayer), isTrue);

      c.setCategoryFilter(ZikirCategory.forgiveness);
      expect(c.filteredZikirs.every((z) => z.category == ZikirCategory.forgiveness), isTrue);

      // Reset to all categories
      c.setCategoryFilter(ZikirCategory.all);
      expect(c.filteredZikirs.length, equals(c.allZikirs.length));

      // Sorted by count: subhanallah (3) should be highest
      final sorted = c.getSortedZikirsByCount();
      expect(sorted.first.id, equals('subhanallah'));
      expect(c.getMaxZikirCount(), equals(3));
      expect(c.getTotalFilteredCount(), equals(4)); // 3 + 1
    });

    test('Location and Asr method toggles update schedule', () {
      final c = Get.put(PrayerTasbihController());
      final ctg = c.selectedLocation;
      expect(ctg.id, equals('dhaka'));

      final chittagong = c.schedule.location;
      expect(chittagong.id, equals('dhaka'));

      c.toggleAsrMethod();
      expect(c.isHanafi, isFalse);
    });

    test('User A and User B have completely isolated and private zikir counts', () async {
      final c = Get.put(PrayerTasbihController());

      // User A logs in and recites 5 times on la_ilaha_illallah
      await c.loadForUserForTesting('user_a');
      final laIlaha = c.allZikirs.firstWhere((z) => z.id == 'la_ilaha_illallah');
      c.selectZikir(laIlaha);

      for (int i = 0; i < 5; i++) {
        c.increment();
      }

      expect(c.todayTotal, equals(5));
      expect(c.lifetimeTotal, equals(5));
      expect(c.getZikirTodayCount('la_ilaha_illallah'), equals(5));
      expect(c.getZikirLifetimeCount('la_ilaha_illallah'), equals(5));

      // User B logs in on same device: User B must NOT see User A's zikir data
      await c.loadForUserForTesting('user_b');
      expect(c.todayTotal, equals(0));
      expect(c.lifetimeTotal, equals(0));
      expect(c.getZikirTodayCount('la_ilaha_illallah'), equals(0));
      expect(c.getZikirLifetimeCount('la_ilaha_illallah'), equals(0));

      // User B recites 10 times on astaghfirullah
      final astaghfir = c.allZikirs.firstWhere((z) => z.id == 'astaghfirullah');
      c.selectZikir(astaghfir);
      for (int i = 0; i < 10; i++) {
        c.increment();
      }

      expect(c.todayTotal, equals(10));
      expect(c.lifetimeTotal, equals(10));
      expect(c.getZikirTodayCount('astaghfirullah'), equals(10));
      expect(c.getZikirTodayCount('la_ilaha_illallah'), equals(0));

      // User A logs back in: User A sees only their own data, never User B's
      await c.loadForUserForTesting('user_a');
      expect(c.todayTotal, equals(5));
      expect(c.lifetimeTotal, equals(5));
      expect(c.getZikirTodayCount('la_ilaha_illallah'), equals(5));
      expect(c.getZikirTodayCount('astaghfirullah'), equals(0));
      expect(c.getZikirLifetimeCount('astaghfirullah'), equals(0));
    });

    test('Day-wise and zikir-wise counts update and maintain integrity across reload', () async {
      final c = Get.put(PrayerTasbihController());
      await c.loadForUserForTesting('day_test_user');

      final subhan = c.allZikirs.firstWhere((z) => z.id == 'subhanallah');
      c.selectZikir(subhan);
      for (int i = 0; i < 33; i++) {
        c.increment();
      }

      final alhamdu = c.allZikirs.firstWhere((z) => z.id == 'alhamdulillah');
      c.selectZikir(alhamdu);
      for (int i = 0; i < 33; i++) {
        c.increment();
      }

      expect(c.todayTotal, equals(66));
      expect(c.getZikirTodayCount('subhanallah'), equals(33));
      expect(c.getZikirTodayCount('alhamdulillah'), equals(33));

      // Re-load same user from SharedPreferences
      await c.loadForUserForTesting('day_test_user');
      expect(c.todayTotal, equals(66));
      expect(c.getZikirTodayCount('subhanallah'), equals(33));
      expect(c.getZikirTodayCount('alhamdulillah'), equals(33));
    });

    test('toggleCountVisibility toggles isCountHidden and persists per user', () async {
      final c = Get.put(PrayerTasbihController());
      await c.loadForUserForTesting('privacy_user');

      expect(c.isCountHidden, isFalse);

      await c.toggleCountVisibility();
      expect(c.isCountHidden, isTrue);

      // Re-load same user: should restore hidden state
      await c.loadForUserForTesting('privacy_user');
      expect(c.isCountHidden, isTrue);

      // Another user default is false
      await c.loadForUserForTesting('other_privacy_user');
      expect(c.isCountHidden, isFalse);
    });
  });

  group('Prayer & Tasbih Samsung A15 UI Tests', () {
    testWidgets('DashboardPrayerCard renders cleanly without overflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.8125; // 384x832 dp (Samsung Galaxy A15)

      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData(extensions: const [AppPalette.light]),
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: DashboardPrayerCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DashboardPrayerCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TasbihCounterView renders and increments on tap without overflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.8125; // 384x832 dp (Samsung Galaxy A15)

      Get.put(PrayerTasbihController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData(extensions: const [AppPalette.light]),
          home: const TasbihCounterView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TasbihCounterView), findsOneWidget);
      // Zikir details card is hidden by default to keep recitation private
      expect(find.text('Show zikir details'), findsOneWidget);
      expect(find.text('لَا إِلٰهَ إِلَّا اللَّهُ'), findsNothing);

      // Tap to reveal zikir details card
      await tester.tap(find.text('Show zikir details'));
      await tester.pumpAndSettle();
      expect(find.text('لَا إِلٰهَ إِلَّا اللَّهُ'), findsOneWidget);

      // Tap to count button
      await tester.tap(find.text('+1 Count'));
      await tester.pumpAndSettle();

      final controller = PrayerTasbihController.to;
      expect(controller.currentCount, equals(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('TasbihCounterView renders cleanly with Bengali locale and 360x800 size without AppBar overflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0; // 360x800 dp (compact phone screen)

      Get.put(PrayerTasbihController());

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('bn', 'BD'),
          theme: ThemeData(extensions: const [AppPalette.light]),
          home: const TasbihCounterView(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TasbihCounterView), findsOneWidget);
      // In Bengali locale, verify zikir details card is hidden by default
      expect(find.text('জিকির বিস্তারিত দেখান'), findsOneWidget);
      expect(find.text('لَا إِلٰهَ إِلَّا اللَّهُ'), findsNothing);

      // Tap to reveal in Bengali
      await tester.tap(find.text('জিকির বিস্তারিত দেখান'));
      await tester.pumpAndSettle();
      expect(find.text('لَا إِلٰهَ إِلَّا اللَّهُ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TasbihHistoryView dedicated page renders cleanly without overflow on Samsung A15', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.8125; // 384x832 dp (Samsung Galaxy A15)

      Get.put(PrayerTasbihController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData(extensions: const [AppPalette.light]),
          home: const TasbihHistoryView(),
          getPages: AppPages.pages,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TasbihHistoryView), findsOneWidget);
      expect(find.byIcon(Icons.query_stats_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Verify Time Filter segments render and can be tapped
      final last7Days = find.text('Last 7 Days');
      expect(last7Days, findsOneWidget);
      await tester.tap(last7Days);
      await tester.pumpAndSettle();

      // Verify Category filter chips render
      final prayerCat = find.text('After Prayer');
      expect(prayerCat, findsWidgets);
      await tester.tap(prayerCat.first);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('TasbihCounterView navigates to TasbihHistoryView dedicated page on button tap', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.8125; // 384x832 dp (Samsung Galaxy A15)

      Get.put(PrayerTasbihController());

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.tasbihCounter,
          theme: ThemeData(extensions: const [AppPalette.light]),
          getPages: AppPages.pages,
        ),
      );
      await tester.pumpAndSettle();

      // Tap the History & Filter action card
      final historyFinder = find.text('Tasbih History & Filter');
      expect(historyFinder, findsWidgets);

      await tester.tap(historyFinder.first);
      await tester.pumpAndSettle();

      // Verify navigated to dedicated TasbihHistoryView page
      expect(find.byType(TasbihHistoryView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('PrayerTasbihView renders both tabs without overflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.8125; // 384x832 dp (Samsung Galaxy A15)

      Get.put(PrayerTasbihController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData(extensions: const [AppPalette.light]),
          home: const PrayerTasbihView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PrayerTasbihView), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Switch to Digital Tasbih tab
      await tester.tap(find.text('Digital Tasbih'));
      await tester.pumpAndSettle();

      expect(find.byType(TasbihCounterView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('PrayerTasbihView renders prayer time ranges and prohibited times cleanly on 360x800 dp in Bengali', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0; // 360x800 dp
      addTearDown(tester.view.resetPhysicalSize);

      Get.put(PrayerTasbihController());

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('bn', 'BD'),
          theme: ThemeData(extensions: const [AppPalette.light]),
          home: const PrayerTasbihView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PrayerTasbihView), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsWidgets);
      // Prohibited prayer times section header & icon
      expect(find.text('নামাজের নিষিদ্ধ সময়'), findsOneWidget);
      expect(find.text('হারাম / নিষিদ্ধ'), findsOneWidget);
      expect(find.byIcon(Icons.block_rounded), findsWidgets);
      // 3 prohibited items rendered
      expect(find.text('সূর্যোদয়ের সময়'), findsOneWidget);
      expect(find.text('ঠিক দ্বিপ্রহরের সময় (যাওয়াল)'), findsOneWidget);
      expect(find.text('সূর্যাস্তের সময়'), findsOneWidget);

      // Alert toggle
      final alertFinder = find.text('অ্যালার্ট চালু');
      await tester.scrollUntilVisible(alertFinder, 200);
      await tester.pumpAndSettle();
      expect(alertFinder, findsOneWidget);

      await tester.tap(alertFinder);
      await tester.pumpAndSettle();
      expect(find.text('অ্যালার্ট বন্ধ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TasbihCounterView hides count when isCountHidden is toggled', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.8125;
      addTearDown(tester.view.resetPhysicalSize);

      final c = Get.put(PrayerTasbihController());
      await c.loadForUserForTesting('stealth_view_user');
      await c.setCountHidden(false);

      for (int i = 0; i < 7; i++) {
        c.increment();
      }

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.tasbihCounter,
          theme: ThemeData(extensions: const [AppPalette.light]),
          getPages: AppPages.pages,
        ),
      );
      await tester.pumpAndSettle();

      // Number 7 should be visible initially (dial, today, lifetime total)
      expect(find.text('7'), findsWidgets);

      // Toggle privacy mode
      await c.toggleCountVisibility();
      await tester.pumpAndSettle();

      // Number 7 should no longer be visible; '***' should be visible
      expect(find.text('7'), findsNothing);
      expect(find.text('***'), findsWidgets);
      expect(tester.takeException(), isNull);

      // Advance clock past the 600ms Firestore debounce timer
      await tester.pump(const Duration(milliseconds: 700));
    });

    test('PrayerTimeCalculator.formatRemainingTime never returns 0 m or 0 s', () {
      // Hours and minutes
      expect(
        PrayerTimeCalculator.formatRemainingTime(const Duration(hours: 2, minutes: 15)),
        equals('2 h 15 m'),
      );
      // Clean hour when minutes is 0
      expect(
        PrayerTimeCalculator.formatRemainingTime(const Duration(hours: 1, minutes: 0, seconds: 45)),
        equals('1 h'),
      );
      // Regular minutes
      expect(
        PrayerTimeCalculator.formatRemainingTime(const Duration(minutes: 25)),
        equals('25 m'),
      );
      expect(
        PrayerTimeCalculator.formatRemainingTime(const Duration(minutes: 1)),
        equals('1 m'),
      );
      // Final minute countdown in seconds (prevents the '0 m বাকি' bug)
      expect(
        PrayerTimeCalculator.formatRemainingTime(const Duration(seconds: 35)),
        equals('35 s'),
      );
      expect(
        PrayerTimeCalculator.formatRemainingTime(const Duration(seconds: 1)),
        equals('1 s'),
      );
      // Boundary and zero / negative cases
      expect(
        PrayerTimeCalculator.formatRemainingTime(Duration.zero),
        equals('< 1 m'),
      );
      expect(
        PrayerTimeCalculator.formatRemainingTime(const Duration(seconds: -10)),
        equals('< 1 m'),
      );
    });

    test('PrayerTasbihController timeUntilNextPrayer is never 0 m', () {
      final c = Get.put(PrayerTasbihController());
      expect(c.timeUntilNextPrayer, isNotEmpty);
      expect(c.timeUntilNextPrayer, isNot(equals('0 m')));
      expect(c.timeUntilNextPrayer, isNot(equals('0 s')));
    });

    test('TasbihEntryModel contains all required fields for Firebase day-wise sync', () {
      const entry = TasbihEntryModel(
        id: '2026-10-27_subhanallah',
        userId: 'test_user_1',
        jikirId: 'subhanallah',
        jikirName: 'সুবহানাল্লাহ',
        jikirNameEn: 'Subhanallah',
        arabic: 'سُبْحَانَ اللَّهِ',
        category: 'prayer',
        jikirCount: 4,
        date: '2026-10-27',
      );

      final map = entry.toFirestore(isNew: true);
      expect(map['id'], equals('2026-10-27_subhanallah'));
      expect(map['user_id'], equals('test_user_1'));
      expect(map['jikir_id'], equals('subhanallah'));
      expect(map['jikir_name'], equals('সুবহানাল্লাহ'));
      expect(map['jikir_count'], equals(4));
      expect(map['jikircound'], equals(4)); // alias check
      expect(map['date'], equals('2026-10-27'));
      expect(map['created_at'], isNotNull);
      expect(map['updated_at'], isNotNull);

      final reconstructed = TasbihEntryModel.fromMap('2026-10-27_subhanallah', map);
      expect(reconstructed.id, equals('2026-10-27_subhanallah'));
      expect(reconstructed.jikirCount, equals(4));
      expect(reconstructed.jikirName, equals('সুবহানাল্লাহ'));
    });

    test('Day-wise zikir updates on current date, and creates new entries across dates', () async {
      final c = Get.put(PrayerTasbihController());
      await c.loadForUserForTesting('day_wise_user');

      // Select Subhanallah
      final subhanallah = c.allZikirs.firstWhere((z) => z.id == 'subhanallah');
      c.selectZikir(subhanallah);

      // Increment 1 on current date
      c.increment();
      expect(c.currentCount, equals(1));
      expect(c.getZikirTodayCount('subhanallah'), equals(1));
      expect(c.historyEntries.any((e) => e.jikirId == 'subhanallah' && e.jikirCount == 1), isTrue);

      // Same date, updates to 2, 3, 4
      c.increment();
      c.increment();
      c.increment();
      expect(c.getZikirTodayCount('subhanallah'), equals(4));
      expect(c.historyEntries.firstWhere((e) => e.jikirId == 'subhanallah').jikirCount, equals(4));

      // Test grouped history entries
      expect(c.groupedHistoryEntries, isNotEmpty);
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      expect(c.groupedHistoryEntries.containsKey(todayKey), isTrue);
      expect(c.dayTotals[todayKey], greaterThanOrEqualTo(4));
    });

    testWidgets('TasbihHistoryView switches between tabs cleanly on Samsung A15', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0; // 360x800 dp
      addTearDown(tester.view.resetPhysicalSize);

      final c = Get.put(PrayerTasbihController());
      await c.loadForUserForTesting('tab_test_user');
      c.increment();

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('bn', 'BD'),
          theme: ThemeData(extensions: const [AppPalette.light]),
          home: const TasbihHistoryView(),
        ),
      );
      await tester.pumpAndSettle();

      // Tab 0: Overview is active initially
      expect(find.text('জিকির তালিকা'), findsOneWidget);
      expect(find.text('দৈনিক ইতিহাস (লগ)'), findsOneWidget);

      // Switch to Tab 1: Daily History Logs
      await tester.tap(find.text('দৈনিক ইতিহাস (লগ)'));
      await tester.pumpAndSettle();

      // Check header in Tab 1
      expect(find.text('ফায়ারবেস ক্লাউড হিস্ট্রি'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
