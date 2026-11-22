import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/time/bangladesh_clock.dart';
import 'package:islamic_app/features/home/services/prayer_calculator.dart';

void main() {
  test('Bangladesh clock crosses midnight at UTC 18:00', () {
    expect(
      bangladeshWallClock(DateTime.utc(2026, 11, 21, 17, 59)),
      DateTime.utc(2026, 11, 21, 23, 59),
    );
    expect(
      bangladeshWallClock(DateTime.utc(2026, 11, 21, 18, 0)),
      DateTime.utc(2026, 11, 22, 0, 0),
    );
  });

  test('Bangladesh wall-clock value stays UTC for Adhan comparisons', () {
    final value = bangladeshWallClock(DateTime.utc(2026, 11, 21, 18, 30));
    expect(value.isUtc, isTrue);
    expect(value.year, 2026);
    expect(value.month, 11);
    expect(value.day, 22);
    expect(value.hour, 0);
    expect(value.minute, 30);
  });
  test('Bangladesh countdown stays aligned with Adhan UTC-offset prayer times', () {
    final now = bangladeshWallClock(DateTime.utc(2026, 11, 21, 18, 30));
    final yesterday = DailyPrayerTimes(
      fajr: DateTime.utc(2026, 11, 21, 5),
      sunrise: DateTime.utc(2026, 11, 21, 6, 15),
      dhuhr: DateTime.utc(2026, 11, 21, 12),
      asr: DateTime.utc(2026, 11, 21, 15, 30),
      maghrib: DateTime.utc(2026, 11, 21, 17, 30),
      isha: DateTime.utc(2026, 11, 21, 19),
    );
    final today = DailyPrayerTimes(
      fajr: DateTime.utc(2026, 11, 22, 5),
      sunrise: DateTime.utc(2026, 11, 22, 6, 15),
      dhuhr: DateTime.utc(2026, 11, 22, 12),
      asr: DateTime.utc(2026, 11, 22, 15, 30),
      maghrib: DateTime.utc(2026, 11, 22, 17, 30),
      isha: DateTime.utc(2026, 11, 22, 19),
    );
    final tomorrow = DailyPrayerTimes(
      fajr: DateTime.utc(2026, 11, 23, 5),
      sunrise: DateTime.utc(2026, 11, 23, 6, 15),
      dhuhr: DateTime.utc(2026, 11, 23, 12),
      asr: DateTime.utc(2026, 11, 23, 15, 30),
      maghrib: DateTime.utc(2026, 11, 23, 17, 30),
      isha: DateTime.utc(2026, 11, 23, 19),
    );

    final plan = PrayerCountdownPlan.calculate(
      now: now,
      yesterday: yesterday,
      today: today,
      tomorrow: tomorrow,
    );
    expect(now, DateTime.utc(2026, 11, 22, 0, 30));
    expect(plan.items.first.nameKey, 'tahajjud');
    expect(plan.items.first.statusKey, 'starts_in');
    expect(
      plan.items.first.target.difference(now),
      const Duration(minutes: 40),
    );
  });

}
