import 'package:adhan/adhan.dart';

enum PrayerCalculation { karachi, muslimWorldLeague, egyptian, dubai }

class DailyPrayerTimes {
  final DateTime fajr;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  const DailyPrayerTimes({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  factory DailyPrayerTimes.calculate({
    required double latitude,
    required double longitude,
    required DateTime date,
    required bool hanafi,
    required PrayerCalculation method,
  }) {
    final coordinates = Coordinates(latitude, longitude);
    final components = DateComponents(date.year, date.month, date.day);
    final params = _parameters(method);
    params.madhab = hanafi ? Madhab.hanafi : Madhab.shafi;
    final times = PrayerTimes(coordinates, components, params);
    return DailyPrayerTimes(
      fajr: times.fajr,
      dhuhr: times.dhuhr,
      asr: times.asr,
      maghrib: times.maghrib,
      isha: times.isha,
    );
  }

  static CalculationParameters _parameters(PrayerCalculation method) {
    switch (method) {
      case PrayerCalculation.karachi:
        return CalculationMethod.karachi.getParameters();
      case PrayerCalculation.muslimWorldLeague:
        return CalculationMethod.muslim_world_league.getParameters();
      case PrayerCalculation.egyptian:
        return CalculationMethod.egyptian.getParameters();
      case PrayerCalculation.dubai:
        return CalculationMethod.dubai.getParameters();
    }
  }

  List<MapEntry<String, DateTime>> entries() => [
        MapEntry('fajr', fajr),
        MapEntry('dhuhr', dhuhr),
        MapEntry('asr', asr),
        MapEntry('maghrib', maghrib),
        MapEntry('isha', isha),
      ];
}
