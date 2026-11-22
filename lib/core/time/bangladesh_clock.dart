import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bangladesh uses UTC+06:00 year-round.
///
/// The Adhan package returns UTC DateTime values with the requested offset
/// applied. This function returns the same representation: a UTC DateTime
/// whose calendar fields show Bangladesh wall-clock time. That keeps prayer
/// countdown comparisons and calendar date labels on the same clock.
const Duration bangladeshUtcOffset = Duration(hours: 6);

DateTime bangladeshWallClock(DateTime instant) =>
    instant.toUtc().add(bangladeshUtcOffset);

/// Injectable source of real instants, also used to test midnight boundaries.
final appClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
