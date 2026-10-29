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

      // Verify items count and end times
      expect(schedule.items.length, equals(6));
      final fajrItem = schedule.items.firstWhere((i) => i.prayer == PrayerName.fajr);
      expect(fajrItem.endTime, equals(schedule.sunrise));
      expect(fajrItem.formatRange(), contains(' – '));

      final dhuhrItem = schedule.items.firstWhere((i) => i.prayer == PrayerName.dhuhr);
      expect(dhuhrItem.endTime, equals(schedule.asr));

      final asrItem = schedule.items.firstWhere((i) => i.prayer == PrayerName.asr);
      expect(asrItem.endTime, equals(schedule.maghrib));

      final maghribItem = schedule.items.firstWhere((i) => i.prayer == PrayerName.maghrib);
      expect(maghribItem.endTime, equals(schedule.isha));

      final ishaItem = schedule.items.firstWhere((i) => i.prayer == PrayerName.isha);
      expect(ishaItem.endTime, isNotNull);
      expect(ishaItem.formatRange(), contains(' – '));
    });

    test('Division list includes all 8 Bangladesh divisions', () {
      expect(BangladeshLocation.divisions.length, equals(8));
      final names = BangladeshLocation.divisions.map((d) => d.id).toList();
      expect(names, containsAll(['dhaka', 'chittagong', 'sylhet', 'rajshahi', 'khulna', 'barishal', 'rangpur', 'mymensingh']));
    });

    test('Includes requested districts Pabna, Sirajganj, Naogaon, Chapainawabganj, and Sylhet', () {
      expect(BangladeshLocation.allLocations.length, greaterThanOrEqualTo(20));

      final pabna = BangladeshLocation.findById('pabna');
      expect(pabna.nameEn, equals('Pabna'));
      expect(pabna.nameBn, equals('পাবনা'));
      expect(pabna.latitude, closeTo(24.0, 0.1));

      final sirajganj = BangladeshLocation.findById('sirajganj');
      expect(sirajganj.nameEn, equals('Sirajganj'));
      expect(sirajganj.nameBn, equals('সিরাজগঞ্জ'));

      final naogaon = BangladeshLocation.findById('naogaon');
      expect(naogaon.nameEn, equals('Naogaon'));
      expect(naogaon.nameBn, equals('নওগাঁ'));

      final chapai = BangladeshLocation.findById('chapainawabganj');
      expect(chapai.nameEn, equals('Chapainawabganj'));
      expect(chapai.nameBn, equals('চাঁপাইনবাবগঞ্জ'));

      final sylhet = BangladeshLocation.findById('sylhet');
      expect(sylhet.nameEn, equals('Sylhet'));
      expect(sylhet.nameBn, equals('সিলেট'));

      // Accurate prayer times can be calculated for Pabna
      final now = DateTime(2026, 10, 27);
      final pabnaSchedule = PrayerTimeCalculator.calculate(date: now, location: pabna);
      expect(pabnaSchedule.fajr.isBefore(pabnaSchedule.sunrise), isTrue);
      expect(pabnaSchedule.sunrise.isBefore(pabnaSchedule.dhuhr), isTrue);
      expect(pabnaSchedule.prohibitedTimes.length, equals(3));
    });

    test('Calculates 3 prohibited (haram) prayer times correctly', () {
      final now = DateTime(2026, 10, 27);
      final schedule = PrayerTimeCalculator.calculate(
        date: now,
        location: BangladeshLocation.defaultLocation,
        isHanafi: true,
      );

      final prohibited = schedule.prohibitedTimes;
      expect(prohibited.length, equals(3));

      // 1. Sunrise
      final sunriseProhibited = prohibited.firstWhere((p) => p.id == 'sunrise');
      expect(sunriseProhibited.start, equals(schedule.sunrise));
      expect(sunriseProhibited.end, equals(schedule.sunrise.add(const Duration(minutes: 15))));

      // 2. Midday / Zawal
      final zawalProhibited = prohibited.firstWhere((p) => p.id == 'zawal');
      expect(zawalProhibited.start, equals(schedule.dhuhr.subtract(const Duration(minutes: 15))));
      expect(zawalProhibited.end, equals(schedule.dhuhr));

      // 3. Sunset
      final sunsetProhibited = prohibited.firstWhere((p) => p.id == 'sunset');
      expect(sunsetProhibited.start, equals(schedule.maghrib.subtract(const Duration(minutes: 15))));
      expect(sunsetProhibited.end, equals(schedule.maghrib));

      // Test active prohibited detection during sunrise window
      final duringSunrise = schedule.sunrise.add(const Duration(minutes: 5));
      expect(schedule.getActiveProhibitedTime(duringSunrise)?.id, equals('sunrise'));
      expect(sunriseProhibited.contains(duringSunrise), isTrue);

      // Test active prohibited detection during midday window
      final duringMidday = schedule.dhuhr.subtract(const Duration(minutes: 5));
      expect(schedule.getActiveProhibitedTime(duringMidday)?.id, equals('zawal'));
      expect(zawalProhibited.contains(duringMidday), isTrue);

      // Test active prohibited detection during sunset window
      final duringSunset = schedule.maghrib.subtract(const Duration(minutes: 5));
      expect(schedule.getActiveProhibitedTime(duringSunset)?.id, equals('sunset'));
      expect(sunsetProhibited.contains(duringSunset), isTrue);

      // Normal prayer time (e.g. 1 hour after Dhuhr) is NOT prohibited
      final normalTime = schedule.dhuhr.add(const Duration(hours: 1));
      expect(schedule.getActiveProhibitedTime(normalTime), isNull);
    });

    test('Prohibited times vary dynamically across dates and support custom bufferMinutes', () {
      final winter = DateTime(2026, 12, 21);
      final summer = DateTime(2026, 6, 21);

      final winterSchedule = PrayerTimeCalculator.calculate(
        date: winter,
        location: BangladeshLocation.defaultLocation,
      );
      final summerSchedule = PrayerTimeCalculator.calculate(
        date: summer,
        location: BangladeshLocation.defaultLocation,
      );

      // Sunrise in winter is later in the morning than summer (e.g. ~6:38 AM vs ~5:12 AM)
      final winterSunriseMinutes = winterSchedule.sunrise.hour * 60 + winterSchedule.sunrise.minute;
      final summerSunriseMinutes = summerSchedule.sunrise.hour * 60 + summerSchedule.sunrise.minute;
      expect(winterSunriseMinutes, greaterThan(summerSunriseMinutes));

      // Sunset in summer is later in the evening than winter (e.g. ~6:49 PM vs ~5:15 PM)
      final winterMaghribMinutes = winterSchedule.maghrib.hour * 60 + winterSchedule.maghrib.minute;
      final summerMaghribMinutes = summerSchedule.maghrib.hour * 60 + summerSchedule.maghrib.minute;
      expect(summerMaghribMinutes, greaterThan(winterMaghribMinutes));

      // Prohibited times vary dynamically day to day
      final winterSunriseProhibited = winterSchedule.prohibitedTimes.firstWhere((p) => p.id == 'sunrise');
      final summerSunriseProhibited = summerSchedule.prohibitedTimes.firstWhere((p) => p.id == 'sunrise');
      expect(winterSunriseProhibited.start != summerSunriseProhibited.start, isTrue);

      // Buffer option (e.g. 20 min caution)
      final twentyMinProhibited = winterSchedule.getProhibitedTimes(bufferMinutes: 20);
      final sunset20 = twentyMinProhibited.firstWhere((p) => p.id == 'sunset');
      expect(sunset20.bufferMinutes, equals(20));
      expect(sunset20.end.difference(sunset20.start).inMinutes, equals(20));
    });

    test('Calculates accurate Hijri date (month, day, year) with BD offset', () {
      final oct29 = DateTime(2026, 10, 29);
      final schedule = PrayerTimeCalculator.calculate(
        date: oct29,
        location: BangladeshLocation.defaultLocation,
        hijriAdjustmentDays: -1, // Bangladesh standard offset
      );

      // Verify year is 1448 AH (NOT 1449)
      expect(schedule.hijriYear, equals(1448));

      // Verify month is Jumada al-Awwal (month 5, NOT Muharram)
      expect(schedule.hijriMonth, equals(5));
      expect(schedule.hijriMonthBn, equals('জমাদিউল আউয়াল'));
      expect(schedule.hijriMonthEn, equals('Jumada al-Awwal'));

      // Verify day is 16 in Bangladesh
      expect(schedule.hijriDay, equals(16));

      // Verify Bengali numerals and string formatting
      expect(schedule.hijriDateBn, equals('১৬ জমাদিউল আউয়াল ১৪৪৮ হিজরি'));
      expect(schedule.hijriDateEn, equals('16 Jumada al-Awwal 1448 AH'));
      expect(schedule.hijriDate, equals('১৬ জমাদিউল আউয়াল ১৪৪৮ হিজরি'));

      // Test historical Bangladesh Islamic dates
      // Ramadan 1, 1445 AH (March 12, 2024 in BD)
      final ramadan2024 = PrayerTimeCalculator.calculateHijri(DateTime(2024, 3, 12), adjustmentDays: -1);
      expect(ramadan2024.day, equals(1));
      expect(ramadan2024.month, equals(9));
      expect(ramadan2024.monthNameBn, equals('রমজান'));
      expect(ramadan2024.year, equals(1445));

      // Eid al-Fitr 1445 AH (April 11, 2024 in BD)
      final eid2024 = PrayerTimeCalculator.calculateHijri(DateTime(2024, 4, 11), adjustmentDays: -1);
      expect(eid2024.day, equals(1));
      expect(eid2024.month, equals(10));
      expect(eid2024.monthNameBn, equals('শাওয়াল'));
      expect(eid2024.year, equals(1445));

      // Global / Saudi offset (0 adjustment) for Oct 29, 2026 is 17 Jumada al-Awwal 1448
      final saudiDate = PrayerTimeCalculator.calculateHijri(oct29, adjustmentDays: 0);
      expect(saudiDate.day, equals(17));
      expect(saudiDate.month, equals(5));
      expect(saudiDate.year, equals(1448));
    });
  });
}
