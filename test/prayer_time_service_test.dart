import 'package:flutter_test/flutter_test.dart';
import 'package:personal_expense/app/data/services/prayer_time_service.dart';

void main() {
  group('PrayerTimeCalculator Tests', () {
    test('Calculates valid prayer times for Dhaka on current date', () {
      final now = DateTime(2026, 10, 27);
      final schedule = PrayerTimeCalculator.calculate(
        date: now,
        location: BangladeshLocation.defaultLocation,
        isHanafi: true,
      );

      expect(schedule.fajr.isBefore(schedule.sunrise), isTrue);
      expect(schedule.sunrise.isBefore(schedule.dhuhr), isTrue);
      expect(schedule.dhuhr.isBefore(schedule.asr), isTrue);
      expect(schedule.asr.isBefore(schedule.maghrib), isTrue);
      expect(schedule.maghrib.isBefore(schedule.isha), isTrue);

      // Verify Dhaka times are in realistic morning / midday / evening windows
      expect(schedule.fajr.hour, anyOf(4, 5));
      expect(schedule.sunrise.hour, anyOf(5, 6));
      expect(schedule.dhuhr.hour, anyOf(11, 12));
      expect(schedule.asr.hour, anyOf(15, 16));
      expect(schedule.maghrib.hour, anyOf(17, 18));
      expect(schedule.isha.hour, anyOf(18, 19));

      // Sehri ends before or at Fajr
      expect(schedule.sehriEnd.isBefore(schedule.fajr), isTrue);

      // Verify Waqt detection
      final midDhuhr = DateTime(2026, 10, 27, 13, 0);
      final currentWaqt = schedule.getCurrentWaqt(midDhuhr);
      expect(currentWaqt.prayer, equals(PrayerName.dhuhr));

      final nextPrayer = schedule.getNextPrayer(midDhuhr);
      expect(nextPrayer.prayer, equals(PrayerName.asr));

      // Verify items count
      expect(schedule.items.length, equals(6));
    });

    test('Division list includes all 8 Bangladesh divisions', () {
      expect(BangladeshLocation.divisions.length, equals(8));
      final names = BangladeshLocation.divisions.map((d) => d.id).toList();
      expect(names, containsAll(['dhaka', 'chittagong', 'sylhet', 'rajshahi', 'khulna', 'barishal', 'rangpur', 'mymensingh']));
    });
  });
}
