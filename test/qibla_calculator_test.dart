import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/features/tools/services/qibla_calculator.dart';

void main() {
  group('QiblaCalculator', () {
    test('calculates a plausible bearing from Dhaka', () {
      final bearing = QiblaCalculator.bearing(
        latitude: 23.8103,
        longitude: 90.4125,
      );
      expect(bearing, closeTo(277.57, 0.1));
    });

    test('normalizes negative and greater-than-360 degree values', () {
      expect(QiblaCalculator.normalizeDegrees(-1), closeTo(359, 0.0001));
      expect(QiblaCalculator.normalizeDegrees(361), closeTo(1, 0.0001));
    });

    test('wraps the relative needle angle across north', () {
      expect(
        QiblaCalculator.relativeAngle(
          qiblaBearing: 10,
          phoneHeading: 350,
        ),
        closeTo(20, 0.0001),
      );
      expect(
        QiblaCalculator.relativeAngle(
          qiblaBearing: 350,
          phoneHeading: 10,
        ),
        closeTo(340, 0.0001),
      );
    });

    test('rejects invalid coordinates and non-finite headings', () {
      expect(
        () => QiblaCalculator.bearing(latitude: 91, longitude: 0),
        throwsArgumentError,
      );
      expect(
        () => QiblaCalculator.relativeAngle(
          qiblaBearing: 90,
          phoneHeading: double.nan,
        ),
        throwsArgumentError,
      );
    });
  });
}
