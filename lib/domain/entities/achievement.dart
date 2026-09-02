import 'package:meta/meta.dart';

/// One collectible achievement badge. Resolved to localized title/
/// description text (and an icon) in the presentation layer — domain
/// entities don't hold localized strings or Flutter types.
enum AchievementId {
  firstPuzzle,
  tenPuzzles,
  fiftyPuzzles,
  hundredPuzzles,
  firstPerfect,
  tenPerfect,
  threeDayStreak,
  sevenDayStreak,
  thirtyDayStreak,
  bigThinker,
  goBig,
}

@immutable
class Achievement {
  const Achievement({required this.id, required this.isUnlocked});

  final AchievementId id;
  final bool isUnlocked;
}
