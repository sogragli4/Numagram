import 'package:nonogram_daily/core/date_key.dart';

/// FNV-1a, 64-bit variant.
///
/// Deliberately hand-rolled instead of using [String.hashCode]: Dart does
/// not guarantee `hashCode` is stable across SDK versions or platforms, so
/// using it here would risk a Dart/Flutter upgrade silently changing which
/// puzzle a given date produces — breaking the zero-storage puzzle archive
/// (every past date is regenerated on demand from its seed).
///
/// Relies on 64-bit two's-complement wraparound integer arithmetic, which
/// Dart guarantees on the platforms this app targets (the Dart VM / AOT —
/// Android and iOS). Do not reuse this on a web/dart2js target without
/// revisiting that assumption.
int fnv1a64(String input) {
  var hash = 0xcbf29ce484222325;
  const prime = 0x100000001b3;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash *= prime;
  }
  return hash;
}

/// Seed for the puzzle generator, derived from a calendar date only (not
/// wall-clock time), so every device produces the same seed for the same
/// day regardless of timezone: callers should pass a date already resolved
/// to the intended calendar day.
int seedForDate(DateTime date) => fnv1a64(formatDateKey(date));
