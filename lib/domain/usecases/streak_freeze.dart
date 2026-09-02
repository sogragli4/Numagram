/// Whether yesterday should be auto-frozen to protect an in-progress
/// streak: yesterday itself wasn't completed or already frozen, the day
/// before it *was* (so there was actually a streak worth protecting —
/// this never manufactures a streak out of nothing), and a freeze is
/// available. Only ever bridges a single missed day; two or more missed
/// days in a row are a genuinely broken streak.
bool shouldAutoFreezeYesterday({
  required Set<DateTime> completedDates,
  required Set<DateTime> frozenDates,
  required DateTime today,
  required int freezesAvailable,
}) {
  if (freezesAvailable <= 0) return false;

  final todayOnly = _dateOnly(today);
  final yesterday = todayOnly.subtract(const Duration(days: 1));
  final dayBeforeYesterday = todayOnly.subtract(const Duration(days: 2));

  final bridged = {
    ...completedDates.map(_dateOnly),
    ...frozenDates.map(_dateOnly),
  };

  if (bridged.contains(yesterday)) return false;
  return bridged.contains(dayBeforeYesterday);
}

/// Whether a new monthly streak-freeze grant is due: [todayMonthKey]
/// (`yyyy-MM`) doesn't match [lastGrantMonthKey] — including the
/// never-granted-yet case, where [lastGrantMonthKey] is `null`.
bool isNewMonthlyFreezeGrantDue({
  required String todayMonthKey,
  required String? lastGrantMonthKey,
}) => todayMonthKey != lastGrantMonthKey;

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
