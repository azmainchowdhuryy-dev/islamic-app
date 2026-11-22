import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/time/bangladesh_clock.dart';

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
}
