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
      for (final entry in result.entries()) {
        expect(entry.value.year, 2026);
        expect(entry.value.month, 11);
        expect(entry.value.day, 20);
      }
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
