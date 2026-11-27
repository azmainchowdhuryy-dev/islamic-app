import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/features/home/services/prayer_calculator.dart';

void main() {
  group('DailyPrayerTimes', () {
    test('calculates all five prayer times for a Bangladesh city', () {
      final result = DailyPrayerTimes.calculate(
        latitude: 24.2513,
        longitude: 89.9167,
        date: DateTime(2026, 11, 20),
        hanafi: true,
        method: PrayerCalculation.karachi,
      );

      expect(result.entries().map((entry) => entry.key).toList(),
          ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']);
      final times = result.entries().map((entry) => entry.value).toList();
      expect(times.every((time) => time.isAfter(DateTime(2026, 11, 18))), isTrue);
      expect(times.every((time) => time.isBefore(DateTime(2026, 11, 21))), isTrue);
      expect(result.sunrise.isAfter(result.fajr), isTrue);
      expect(result.sunrise.isBefore(result.dhuhr), isTrue);
      for (var i = 1; i < times.length; i++) {
        expect(times[i].isAfter(times[i - 1]), isTrue,
            reason: 'Prayer times should be in chronological order');
      }
    });

    test('Isha deadline is the following Fajr, never the following Dhuhr', () {
      final nextFajr = DateTime(2026, 11, 23, 5);
      final nextDhuhr = DateTime(2026, 11, 23, 12);
      final deadline = DailyPrayerTimes.ishaEndTime(nextFajr);

      expect(deadline, nextFajr);
      expect(deadline.isBefore(nextDhuhr), isTrue);
    });

    test('Tahajjud milestone starts at the beginning of the final third', () {
      final maghrib = DateTime(2026, 11, 20, 17, 30);
      final nextFajr = DateTime(2026, 11, 21, 4, 45);
      final nightSeconds = nextFajr.difference(maghrib).inSeconds;
      final start = DailyPrayerTimes.tahajjudStart(maghrib, nextFajr);

      expect(
        start.difference(maghrib).inSeconds,
        closeTo(nightSeconds * 2 / 3, 1),
      );
      expect(
        nextFajr.difference(start).inSeconds,
        closeTo(nightSeconds / 3, 1),
      );
    });

    test('Duha starts when the fifteen-minute sunrise restriction ends', () {
      final sunrise = DateTime(2026, 11, 21, 6, 10);
      expect(
        DailyPrayerTimes.duhaStart(sunrise),
        DateTime(2026, 11, 21, 6, 25),
      );
    });

    test('Hanafi Asr is later than Shafi Asr for the same date and place', () {
      final hanafi = DailyPrayerTimes.calculate(
        latitude: 24.2513,
        longitude: 89.9167,
        date: DateTime(2026, 11, 20),
        hanafi: true,
        method: PrayerCalculation.karachi,
      );
      final shafi = DailyPrayerTimes.calculate(
        latitude: 24.2513,
        longitude: 89.9167,
        date: DateTime(2026, 11, 20),
        hanafi: false,
        method: PrayerCalculation.karachi,
      );

      expect(hanafi.asr.isAfter(shafi.asr), isTrue);
    });
  });

  group('PrayerCountdownPlan', () {
    final day = DateTime(2026, 11, 22);
    DailyPrayerTimes times(DateTime date) => DailyPrayerTimes(
          fajr: DateTime(date.year, date.month, date.day, 5),
          sunrise: DateTime(date.year, date.month, date.day, 6, 15),
          dhuhr: DateTime(date.year, date.month, date.day, 12),
          asr: DateTime(date.year, date.month, date.day, 15, 30),
          maghrib: DateTime(date.year, date.month, date.day, 17, 45),
          isha: DateTime(date.year, date.month, date.day, 19),
        );

    late final yesterday = times(day.subtract(const Duration(days: 1)));
    late final today = times(day);
    late final tomorrow = times(day.add(const Duration(days: 1)));

    PrayerCountdownPlan planAt(int hour, [int minute = 0]) =>
        PrayerCountdownPlan.calculate(
          now: DateTime(day.year, day.month, day.day, hour, minute),
          yesterday: yesterday,
          today: today,
          tomorrow: tomorrow,
        );

    test("uses yesterday Maghrib and today's Fajr after midnight", () {
      final plan = planAt(0, 30);
      final expectedStart = DailyPrayerTimes.tahajjudStart(
        yesterday.maghrib,
        today.fajr,
      );

      expect(plan.items.first.nameKey, 'tahajjud');
      expect(plan.items.first.statusKey, 'starts_in');
      expect(plan.items.first.target, expectedStart);
      expect(plan.items[1].target, today.fajr);
    });

    test('shows Tahajjud ending countdown during the last third', () {
      final plan = planAt(2);

      expect(plan.items.first.nameKey, 'tahajjud');
      expect(plan.items.first.statusKey, 'ends_in');
      expect(plan.items.first.target, today.fajr);
      expect(plan.items[1].nameKey, 'fajr');
    });

    test('shows Fajr end and Duha start before sunrise', () {
      final plan = planAt(5, 30);

      expect(plan.items.first.nameKey, 'fajr');
      expect(plan.items.first.target, today.sunrise);
      expect(plan.items[1].nameKey, 'duha');
      expect(plan.items[1].target, today.sunrise.add(const Duration(minutes: 15)));
    });


    test('warns shortly before the sunrise prohibited window', () {
      final plan = planAt(6, 12);

      expect(plan.items.first.nameKey, 'fajr');
      expect(plan.items.first.isImminent, isTrue);
      expect(plan.items.first.detailKey, 'sunrise_window');
    });

    test('warns shortly before the zenith prohibited window', () {
      final plan = planAt(11, 47);

      expect(plan.items.first.nameKey, 'duha');
      expect(plan.items.first.isImminent, isTrue);
      expect(plan.items.first.detailKey, 'zenith_window');
    });

    test('warns shortly before the sunset prohibited window', () {
      final plan = planAt(17, 27);

      expect(plan.items.first.nameKey, 'asr');
      expect(plan.items.first.isImminent, isTrue);
      expect(plan.items.first.detailKey, 'sunset_window');
    });

    test('marks sunrise prohibited window and counts down to its end', () {
      final plan = planAt(6, 20);

      expect(plan.items.first.isProhibited, isTrue);
      expect(plan.items.first.nameKey, 'prohibited_time');
      expect(plan.items.first.detailKey, 'sunrise_window');
      expect(plan.items.first.target, today.sunrise.add(const Duration(minutes: 15)));
      expect(plan.items[1].nameKey, 'duha');
    });

    test('shows Duha ending and Dhuhr start during Duha time', () {
      final plan = planAt(8);

      expect(plan.items.first.nameKey, 'duha');
      expect(plan.items.first.statusKey, 'ends_in');
      expect(plan.items.first.target, today.dhuhr.subtract(const Duration(minutes: 10)));
      expect(plan.items[1].nameKey, 'dhuhr');
    });

    test('marks the ten-minute zenith window as prohibited', () {
      final plan = planAt(11, 55);

      expect(plan.items.first.isProhibited, isTrue);
      expect(plan.items.first.detailKey, 'zenith_window');
      expect(plan.items.first.target, today.dhuhr);
      expect(plan.items[1].nameKey, 'dhuhr');
    });

    test('shows Dhuhr end and Asr start between Dhuhr and Asr', () {
      final plan = planAt(13);

      expect(plan.items.first.nameKey, 'dhuhr');
      expect(plan.items.first.target, today.asr);
      expect(plan.items[1].nameKey, 'asr');
    });

    test('marks the sunset prohibited window before Maghrib', () {
      final plan = planAt(17, 35);

      expect(plan.items.first.isProhibited, isTrue);
      expect(plan.items.first.detailKey, 'sunset_window');
      expect(plan.items.first.target, today.maghrib);
      expect(plan.items[1].nameKey, 'maghrib');
    });

    test('shows Maghrib end and Isha start during Maghrib', () {
      final plan = planAt(18);

      expect(plan.items.first.nameKey, 'maghrib');
      expect(plan.items.first.statusKey, 'ends_in');
      expect(plan.items.first.target, today.isha);
      expect(plan.items[1].nameKey, 'isha');
    });

    test('shows Isha end and next Tahajjud start during Isha', () {
      final plan = planAt(20);

      expect(plan.items.first.nameKey, 'isha');
      expect(plan.items.first.target, DailyPrayerTimes.ishaEndTime(tomorrow.fajr));
      expect(plan.items.first.target.isBefore(tomorrow.dhuhr), isTrue);
      expect(plan.items[1].nameKey, 'tahajjud');
      expect(
        plan.items[1].target,
        DailyPrayerTimes.tahajjudStart(today.maghrib, tomorrow.fajr),
      );
    });
  });

}
