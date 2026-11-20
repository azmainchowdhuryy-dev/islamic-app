/// Returns the date-based Daily Hadith position.
int dailyHadithIndex(DateTime date, int itemCount) {
  if (itemCount <= 0) {
    throw ArgumentError.value(itemCount, 'itemCount', 'Must be positive.');
  }

  // UTC calendar dates avoid daylight-saving duration changes.
  final day = DateTime.utc(date.year, date.month, date.day);
  final firstDay = DateTime.utc(date.year, 1, 1);
  return day.difference(firstDay).inDays % itemCount;
}
