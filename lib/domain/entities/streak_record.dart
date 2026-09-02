/// Current/longest daily-puzzle streak, derived from the set of completed
/// calendar dates — never stored directly, so it can never drift out of
/// sync with the completion records it's computed from.
class StreakRecord {
  const StreakRecord({
    required this.currentStreak,
    required this.longestStreak,
    required this.completedDates,
  });

  factory StreakRecord.compute({
    required Set<DateTime> completedDates,
    required DateTime today,
  }) {
    final normalized = completedDates.map(_dateOnly).toSet();
    final todayOnly = _dateOnly(today);

    var current = 0;
    if (normalized.contains(todayOnly) ||
        normalized.contains(todayOnly.subtract(const Duration(days: 1)))) {
      var cursor = normalized.contains(todayOnly)
          ? todayOnly
          : todayOnly.subtract(const Duration(days: 1));
      while (normalized.contains(cursor)) {
        current++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
    }

    var longest = 0;
    var running = 0;
    DateTime? previous;
    for (final date in normalized.toList()..sort()) {
      if (previous != null &&
          date.difference(previous) == const Duration(days: 1)) {
        running++;
      } else {
        running = 1;
      }
      if (running > longest) longest = running;
      previous = date;
    }

    return StreakRecord(
      currentStreak: current,
      longestStreak: longest,
      completedDates: normalized,
    );
  }

  final int currentStreak;
  final int longestStreak;
  final Set<DateTime> completedDates;

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
