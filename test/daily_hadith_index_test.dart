import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/features/home/services/daily_hadith_index.dart';

void main() {
  group('dailyHadithIndex', () {
    test('changes to the next entry on the following calendar day', () {
      final first = dailyHadithIndex(DateTime(2026, 11, 20), 13);
      final next = dailyHadithIndex(DateTime(2026, 11, 21), 13);
      expect(next, (first + 1) % 13);
    });

    test('starts a new yearly sequence on January 1', () {
      expect(dailyHadithIndex(DateTime(2026, 1, 1), 13), 0);
      expect(dailyHadithIndex(DateTime(2027, 1, 1), 13), 0);
    });

    test('rejects an empty hadith collection', () {
      expect(
        () => dailyHadithIndex(DateTime(2026, 11, 20), 0),
        throwsArgumentError,
      );
    });
  });
}
