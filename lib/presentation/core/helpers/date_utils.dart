final class DateUtils {
  static const int millisecondsInDay = 1000 * 60 * 60 * 24;

  static int getDayIndex({required DateTime from}) =>
      (from.millisecondsSinceEpoch + from.timeZoneOffset.inMilliseconds) ~/ millisecondsInDay;

  static int getTodayIndex() => DateUtils.getDayIndex(from: DateTime.now());

  static DateTime getDateFromDayIndex(int dayIndex) =>
      DateTime.fromMillisecondsSinceEpoch(millisecondsInDay * dayIndex);

  static DateTime getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1)); // Monday
  }

  static DateTime getMonthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime getYearStart(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  static DateTime getTwoWeeksAgoMonday(DateTime date) {
    final DateTime thisWeekStart = getWeekStart(date);
    return thisWeekStart.subtract(const Duration(days: 7));
  }

  static DateTime getLastDayOfWeek(DateTime date) {
    int currentWeekday = date.weekday;
    int daysToLastDay = DateTime.sunday - currentWeekday;
    return date.add(Duration(days: daysToLastDay));
  }
}
