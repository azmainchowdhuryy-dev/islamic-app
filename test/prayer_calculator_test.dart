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

    test('Duha milestone starts twenty minutes after sunrise', () {
      final sunrise = DateTime(2026, 11, 21, 6, 10);
      expect(
        DailyPrayerTimes.duhaStart(sunrise),
        DateTime(2026, 11, 21, 6, 30),
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
}
