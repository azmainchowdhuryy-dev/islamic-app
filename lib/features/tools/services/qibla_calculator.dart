import 'dart:math' as math;

/// Great-circle bearing from a selected city to the Kaaba.
class QiblaCalculator {
  static const double kaabaLatitude = 21.422511;
  static const double kaabaLongitude = 39.82615;

  static double bearing({
    required double latitude,
    required double longitude,
  }) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw ArgumentError('Invalid latitude or longitude.');
    }

    final lat = latitude * math.pi / 180;
    final lon = longitude * math.pi / 180;
    final kaabaLat = kaabaLatitude * math.pi / 180;
    final kaabaLon = kaabaLongitude * math.pi / 180;
    final deltaLon = kaabaLon - lon;

    final y = math.sin(deltaLon);
    final x = math.cos(lat) * math.tan(kaabaLat) -
        math.sin(lat) * math.cos(deltaLon);
    final degrees = math.atan2(y, x) * 180 / math.pi;
    return normalizeDegrees(degrees);
  }

  static double normalizeDegrees(double degrees) {
    if (!degrees.isFinite) {
      throw ArgumentError.value(degrees, 'degrees', 'Must be finite.');
    }
    return (degrees % 360 + 360) % 360;
  }

  /// Clockwise rotation from the phone's current heading to Qibla.
  static double relativeAngle({
    required double qiblaBearing,
    required double phoneHeading,
  }) {
    if (!qiblaBearing.isFinite || !phoneHeading.isFinite) {
      throw ArgumentError('Bearing and heading must be finite.');
    }
    return normalizeDegrees(qiblaBearing - phoneHeading);
  }
}
