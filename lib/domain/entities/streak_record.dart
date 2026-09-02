/// Current/longest daily-puzzle streak, derived from the set of completed
/// calendar dates — never stored directly, so it can never drift out of
/// sync with the completion records it's computed from.
class StreakRecord {
  const StreakRecord({
    required this.currentStreak,
    required this.longestStreak,
    required this.completedDates,
    required this.frozenDates,
  });

  factory StreakRecord.compute({
    required Set<DateTime> completedDates,
    required DateTime today,
    Set<DateTime> frozenDates = const {},
  }) {
    final normalizedCompleted = completedDates.map(_dateOnly).toSet();
    final normalizedFrozen = frozenDates.map(_dateOnly).toSet();
    // A streak freeze bridges a missed day for continuity purposes only —
    // it never counts as an actual completion, so `completedDates` below
    // stays exactly what was actually solved.
    final bridged = {...normalizedCompleted, ...normalizedFrozen};
    final todayOnly = _dateOnly(today);

    var current = 0;
    if (bridged.contains(todayOnly) ||
        bridged.contains(todayOnly.subtract(const Duration(days: 1)))) {
      var cursor = bridged.contains(todayOnly)
          ? todayOnly
          : todayOnly.subtract(const Duration(days: 1));
      while (bridged.contains(cursor)) {
        current++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
    }

    var longest = 0;
    var running = 0;
    DateTime? previous;
    for (final date in bridged.toList()..sort()) {
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
      completedDates: normalizedCompleted,
      frozenDates: normalizedFrozen,
    );
  }

  final int currentStreak;
  final int longestStreak;
  final Set<DateTime> completedDates;

  /// Dates a streak freeze bridged — not actual completions, just a gap
  /// that didn't break the streak. See [StreakRecord.compute]'s doc
  /// comment.
  final Set<DateTime> frozenDates;

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
