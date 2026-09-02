/// Canonical `yyyy-MM-dd` calendar-date key, used everywhere a date needs
/// to be a stable string: the daily puzzle seed input, Isar storage, and
/// the archive/calendar UI. One implementation so all three always agree.
String formatDateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime parseDateKey(String key) {
  final parts = key.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

/// Canonical `yyyy-MM` calendar-month key — used to track "has this
/// month's grant already happened" style state (e.g. the monthly streak
/// freeze grant) without needing a full date.
String formatMonthKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$y-$m';
}
