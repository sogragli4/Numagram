import 'package:meta/meta.dart';
import 'package:nonogram_daily/core/constants.dart';

/// One selectable size on the Free Play screen.
@immutable
class FreePlaySizePreset {
  const FreePlaySizePreset(this.width, this.height, {this.requiredStreak = 0});

  final int width;
  final int height;

  /// Longest-ever streak needed to play this size. 0 means always
  /// available.
  final int requiredStreak;

  bool isUnlockedAt(int longestStreak) => longestStreak >= requiredStreak;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FreePlaySizePreset &&
          width == other.width &&
          height == other.height &&
          requiredStreak == other.requiredStreak);

  @override
  int get hashCode => Object.hash(width, height, requiredStreak);
}

/// Every Free Play size, in display order. The largest is a
/// streak-milestone unlock (see [FreePlaySizeUnlocks]) — personal
/// progression, unlike the daily puzzle's day-of-week size rhythm
/// (`dailySizeForDate`), which stays the same for every player on a given
/// date.
const freePlaySizePresets = [
  FreePlaySizePreset(5, 5),
  FreePlaySizePreset(10, 10),
  FreePlaySizePreset(15, 15),
  FreePlaySizePreset(
    20,
    20,
    requiredStreak: FreePlaySizeUnlocks.extraLargeStreakDays,
  ),
];
