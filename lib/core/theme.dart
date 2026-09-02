import 'package:flutter/material.dart';
import 'package:nonogram_daily/core/constants.dart';
import 'package:nonogram_daily/core/design_system/app_colors.dart';

/// An unlockable colour theme: a seed colour plus the longest-streak
/// milestone that unlocks it. Unlocked by streak, never by ad (Phase 5
/// spec) — nothing here reads `AdService`.
///
/// [id] is what's actually persisted (`AppSettings.selectedThemeId`) —
/// the enum itself can't live in `domain/`, since it depends on
/// Flutter's `Color`.
enum AppColorTheme {
  classic(id: 'classic', seedColor: Color(0xFF3D5AFE), requiredStreak: 0),
  sunset(
    id: 'sunset',
    seedColor: Color(0xFFE8590C),
    requiredStreak: ThemeUnlocks.sunsetStreakDays,
  ),
  forest(
    id: 'forest',
    seedColor: Color(0xFF2E7D32),
    requiredStreak: ThemeUnlocks.forestStreakDays,
  );

  const AppColorTheme({
    required this.id,
    required this.seedColor,
    required this.requiredStreak,
  });

  final String id;
  final Color seedColor;

  /// Longest-ever streak (not current — a broken streak doesn't take an
  /// earned theme away) needed to unlock this theme. 0 means always
  /// unlocked.
  final int requiredStreak;

  bool isUnlockedAt(int longestStreak) => longestStreak >= requiredStreak;

  static AppColorTheme fromId(String id) =>
      values.firstWhere((t) => t.id == id, orElse: () => classic);
}

/// Central theme definitions.
abstract final class AppTheme {
  static ThemeData light(Color seed) => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: seed),
    extensions: const [AppColors.light],
  );

  static ThemeData dark(Color seed) => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ),
    extensions: const [AppColors.dark],
  );
}

/// Colors `BoardPainter` draws cells with. Two fixed sets rather than
/// deriving from [ColorScheme]: cell color meaning (filled / marked /
/// wrong / completed) must stay visually distinct and consistent
/// regardless of the app's light/dark or unlockable theme — see
/// [BoardPalette.standard] vs [BoardPalette.colorblindSafe].
class BoardPalette {
  const BoardPalette({
    required this.filled,
    required this.markStroke,
    required this.wrongFlash,
    required this.completedLineTint,
  });

  /// Default palette. Deliberately avoids relying on a pure red/green
  /// pairing for mistake vs. completed-line feedback, but isn't tuned as
  /// carefully as [colorblindSafe] — that's what the accessibility
  /// setting is for.
  static const standard = BoardPalette(
    filled: Color(0xFF2B2D42),
    markStroke: Color(0xFF8D99AE),
    wrongFlash: Color(0xFFEF476F),
    completedLineTint: Color(0xFF06D6A0),
  );

  /// Okabe–Ito colorblind-safe palette: blue / grey / vermillion /
  /// bluish-green, chosen so filled, wrong-flash, and completed-line
  /// states stay distinguishable under protanopia, deuteranopia, and
  /// tritanopia.
  static const colorblindSafe = BoardPalette(
    filled: Color(0xFF0072B2),
    markStroke: Color(0xFF999999),
    wrongFlash: Color(0xFFE69F00),
    completedLineTint: Color(0xFF009E73),
  );

  final Color filled;
  final Color markStroke;
  final Color wrongFlash;
  final Color completedLineTint;
}
