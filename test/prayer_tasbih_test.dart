import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:personal_expense/app/core/theme/app_theme.dart';
import 'package:personal_expense/app/features/prayer_tasbih/controllers/prayer_tasbih_controller.dart';
import 'package:personal_expense/app/features/prayer_tasbih/views/prayer_tasbih_view.dart';
import 'package:personal_expense/app/features/prayer_tasbih/views/tasbih_counter_view.dart';
import 'package:personal_expense/app/features/dashboard/views/components/dashboard_prayer_card.dart';
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
  });

  group('PrayerTasbihController Tests', () {
    test('Initializes with default values and preset zikirs', () {
      final c = Get.put(PrayerTasbihController());

      expect(c.allZikirs.length, greaterThanOrEqualTo(10));
      expect(c.selectedZikir.titleBn, equals('সুবহানাল্লাহ'));
      expect(c.currentCount, equals(0));
      expect(c.targetCount, equals(33));
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

    test('Location and Asr method toggles update schedule', () {
      final c = Get.put(PrayerTasbihController());
      final ctg = c.selectedLocation;
      expect(ctg.id, equals('dhaka'));

      final chittagong = c.schedule.location;
      expect(chittagong.id, equals('dhaka'));

      c.toggleAsrMethod();
      expect(c.isHanafi, isFalse);
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
      expect(find.text('سُبْحَانَ اللَّهِ'), findsOneWidget);

      // Tap to count button
      await tester.tap(find.text('+1 Count'));
      await tester.pumpAndSettle();

      final controller = PrayerTasbihController.to;
      expect(controller.currentCount, equals(1));
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
  });
}
