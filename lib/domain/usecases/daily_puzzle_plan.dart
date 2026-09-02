import 'package:nonogram_daily/domain/entities/grid_size.dart';

/// The daily puzzle's size on an ordinary weekday (Monday–Friday) — the
/// size the Phase 1 difficulty scorer was calibrated against ("10x10
/// lands in medium").
const dailyPuzzleWidth = 10;
const dailyPuzzleHeight = 10;

/// Saturday's larger "weekend challenge" size.
const _weekendChallengeSize = GridSize(15, 15);

/// Sunday's smaller "light day" size — a deliberate breather between one
/// week's weekend challenge and the next.
const _lightDaySize = GridSize(5, 5);

/// The daily puzzle's grid size for [date] — a pure function of the
/// calendar date (via [DateTime.weekday]), so every player still sees the
/// exact same size on the exact same day, preserving the "one shared
/// daily puzzle" brief. Varies by day of week rather than by any
/// individual player's streak: a size tied to personal progress would
/// mean two players opening the app on the same date see differently
/// shaped puzzles, breaking that shared ritual. Addresses the founder's
/// "avoid repetition fatigue" note from a different angle than streak
/// milestones (see `AppColorTheme`/`FreePlaySizeUnlocks`), which stays
/// personal and lives in Free Play instead.
GridSize dailySizeForDate(DateTime date) => switch (date.weekday) {
  DateTime.saturday => _weekendChallengeSize,
  DateTime.sunday => _lightDaySize,
  _ => const GridSize(dailyPuzzleWidth, dailyPuzzleHeight),
};
