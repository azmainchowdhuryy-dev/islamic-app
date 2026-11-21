import 'package:adhan/adhan.dart';

enum PrayerCalculation { karachi, muslimWorldLeague, egyptian, dubai }

class DailyPrayerTimes {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  const DailyPrayerTimes({
    required this.fajr,
    required this.sunrise,
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
      sunrise: times.sunrise,
      dhuhr: times.dhuhr,
      asr: times.asr,
      maghrib: times.maghrib,
      isha: times.isha,
    );
  }

  /// Start of the final third of the night, used as the Tahajjud
  /// countdown milestone. The night runs from Maghrib to the following Fajr.
  static DateTime tahajjudStart(DateTime maghrib, DateTime nextFajr) {
    final night = nextFajr.difference(maghrib);
    if (night.inSeconds <= 0) {
      throw ArgumentError('The next Fajr must be after Maghrib.');
    }
    return maghrib.add(Duration(seconds: (night.inSeconds * 2 / 3).round()));
  }

  /// Duha begins after the sun has risen by approximately one spear-length.
  /// Twenty minutes after the calculated sunrise is used as a practical buffer.
  static DateTime duhaStart(DateTime sunrise) =>
      sunrise.add(const Duration(minutes: 20));

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

/// A single live countdown shown in the Home prayer card.
class PrayerCountdownItem {
  final String nameKey;
  final String statusKey;
  final DateTime target;
  final bool isProhibited;
  final bool isImminent;
  final String? detailKey;

  const PrayerCountdownItem({
    required this.nameKey,
    required this.statusKey,
    required this.target,
    this.isProhibited = false,
    this.isImminent = false,
    this.detailKey,
  });
}

/// Selects the two most relevant prayer milestones for the current time.
class PrayerCountdownPlan {
  final List<PrayerCountdownItem> items;

  const PrayerCountdownPlan(this.items);

  factory PrayerCountdownPlan.calculate({
    required DateTime now,
    required DailyPrayerTimes yesterday,
    required DailyPrayerTimes today,
    required DailyPrayerTimes tomorrow,
    int sunriseProhibitedMinutes = 15,
    int zenithProhibitedMinutes = 10,
    int sunsetProhibitedMinutes = 15,
  }) {
    PrayerCountdownItem item(
      String name,
      String status,
      DateTime target, {
      bool prohibited = false,
      bool imminent = false,
      String? detail,
    }) =>
        PrayerCountdownItem(
          nameKey: name,
          statusKey: status,
          target: target,
          isProhibited: prohibited,
          isImminent: imminent,
          detailKey: detail,
        );

    PrayerCountdownPlan pair(
      PrayerCountdownItem first,
      PrayerCountdownItem second,
    ) =>
        PrayerCountdownPlan([first, second]);

    final beforeTodayFajr = now.isBefore(today.fajr);
    final nightMaghrib = beforeTodayFajr ? yesterday.maghrib : today.maghrib;
    final nextFajr = beforeTodayFajr ? today.fajr : tomorrow.fajr;
    final tahajjudStart = DailyPrayerTimes.tahajjudStart(
      nightMaghrib,
      nextFajr,
    );
    final sunriseEnd = today.sunrise.add(
      Duration(minutes: sunriseProhibitedMinutes),
    );
    final duhaStart = DailyPrayerTimes.duhaStart(today.sunrise);
    final zenithStart = today.dhuhr.subtract(
      Duration(minutes: zenithProhibitedMinutes),
    );
    final sunsetStart = today.maghrib.subtract(
      Duration(minutes: sunsetProhibitedMinutes),
    );

    // Midnight through Fajr uses yesterday's Maghrib and today's Fajr.
    if (beforeTodayFajr) {
      if (now.isBefore(tahajjudStart)) {
        return pair(
          item('tahajjud', 'starts_in', tahajjudStart),
          item('fajr', 'starts_in', today.fajr),
        );
      }
      return pair(
        item('tahajjud', 'ends_in', today.fajr),
        item('fajr', 'starts_in', today.fajr),
      );
    }

    if (now.isBefore(today.sunrise)) {
      return pair(
        item(
          'fajr',
          'ends_in',
          today.sunrise,
          imminent: !now.isBefore(today.sunrise.subtract(const Duration(minutes: 5))),
          detail: !now.isBefore(today.sunrise.subtract(const Duration(minutes: 5)))
              ? 'sunrise_window'
              : null,
        ),
        item('duha', 'starts_in', duhaStart),
      );
    }

    if (now.isBefore(sunriseEnd)) {
      return pair(
        item(
          'prohibited_time',
          'ends_in',
          sunriseEnd,
          prohibited: true,
          detail: 'sunrise_window',
        ),
        item('duha', 'starts_in', duhaStart),
      );
    }

    if (now.isBefore(duhaStart)) {
      return pair(
        item('duha', 'starts_in', duhaStart),
        item('dhuhr', 'starts_in', today.dhuhr),
      );
    }

    if (now.isBefore(zenithStart)) {
      return pair(
        item(
          'duha',
          'ends_in',
          zenithStart,
          imminent: !now.isBefore(zenithStart.subtract(const Duration(minutes: 5))),
          detail: !now.isBefore(zenithStart.subtract(const Duration(minutes: 5)))
              ? 'zenith_window'
              : null,
        ),
        item('dhuhr', 'starts_in', today.dhuhr),
      );
    }

    if (now.isBefore(today.dhuhr)) {
      return pair(
        item(
          'prohibited_time',
          'ends_in',
          today.dhuhr,
          prohibited: true,
          detail: 'zenith_window',
        ),
        item('dhuhr', 'starts_in', today.dhuhr),
      );
    }

    if (now.isBefore(today.asr)) {
      return pair(
        item('dhuhr', 'ends_in', today.asr),
        item('asr', 'starts_in', today.asr),
      );
    }

    if (now.isBefore(sunsetStart)) {
      return pair(
        item(
          'asr',
          'ends_in',
          today.maghrib,
          imminent: !now.isBefore(sunsetStart.subtract(const Duration(minutes: 5))),
          detail: !now.isBefore(sunsetStart.subtract(const Duration(minutes: 5)))
              ? 'sunset_window'
              : null,
        ),
        item('maghrib', 'starts_in', today.maghrib),
      );
    }

    if (now.isBefore(today.maghrib)) {
      return pair(
        item(
          'prohibited_time',
          'ends_in',
          today.maghrib,
          prohibited: true,
          detail: 'sunset_window',
        ),
        item('maghrib', 'starts_in', today.maghrib),
      );
    }

    if (now.isBefore(today.isha)) {
      return pair(
        item('maghrib', 'ends_in', today.isha),
        item('isha', 'starts_in', today.isha),
      );
    }

    if (now.isBefore(tahajjudStart)) {
      return pair(
        item('isha', 'ends_in', tomorrow.fajr),
        item('tahajjud', 'starts_in', tahajjudStart),
      );
    }

    return pair(
      item('tahajjud', 'ends_in', tomorrow.fajr),
      item('fajr', 'starts_in', tomorrow.fajr),
    );
  }
}
