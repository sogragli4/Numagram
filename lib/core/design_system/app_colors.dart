import 'package:flutter/material.dart';

/// The word game's brand palette — navy + warm orange, newspaper-puzzle
/// inspired (CLAUDE.MD, "Kelime Bulmacası" ana menü referansı). Deliberately
/// separate from `core/theme.dart`'s seed-based `ColorScheme` (which
/// Nonogram's own screens use, unlockable-theme included) rather than
/// replacing it — the two games are allowed their own visual identity
/// while sharing every other layer; see the "scope" note where this is
/// wired into `AppTheme` for the open question of whether that should
/// change later.
///
/// A [ThemeExtension] so it participates in `Theme.of(context)` and
/// resolves per light/dark like every built-in `ColorScheme` token —
/// access it via `context.appColors`, never by importing `AppColors.light`
/// / `AppColors.dark` directly in a widget.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.navy,
    required this.orange,
    required this.background,
    required this.surface,
    required this.success,
    required this.error,
    required this.warning,
    required this.puzzleCell,
    required this.puzzleCellSelected,
    required this.puzzleWordSelected,
    required this.puzzleBlocked,
    required this.puzzleCorrect,
    required this.puzzleWrong,
  });

  final Color navy;
  final Color orange;
  final Color background;
  final Color surface;
  final Color success;
  final Color error;
  final Color warning;

  final Color puzzleCell;
  final Color puzzleCellSelected;
  final Color puzzleWordSelected;
  final Color puzzleBlocked;
  final Color puzzleCorrect;
  final Color puzzleWrong;

  static const light = AppColors(
    navy: Color(0xFF1B2A41),
    orange: Color(0xFFC9843D),
    background: Color(0xFFF3EEE3),
    surface: Color(0xFFFFFFFF),
    success: Color(0xFF3D8361),
    error: Color(0xFFB5433D),
    warning: Color(0xFFC9A227),
    puzzleCell: Color(0xFFFFFFFF),
    puzzleCellSelected: Color(0xFFF3DCBB),
    puzzleWordSelected: Color(0xFFF8ECD8),
    puzzleBlocked: Color(0xFF1B2A41),
    puzzleCorrect: Color(0xFF3D8361),
    puzzleWrong: Color(0xFFB5433D),
  );

  static const dark = AppColors(
    navy: Color(0xFF0F1826),
    orange: Color(0xFFE0A059),
    background: Color(0xFF14181F),
    surface: Color(0xFF1E242E),
    success: Color(0xFF63B08A),
    error: Color(0xFFD97369),
    warning: Color(0xFFDCBB55),
    puzzleCell: Color(0xFF1E242E),
    puzzleCellSelected: Color(0xFF3D3423),
    puzzleWordSelected: Color(0xFF262B22),
    puzzleBlocked: Color(0xFF0A0F17),
    puzzleCorrect: Color(0xFF63B08A),
    puzzleWrong: Color(0xFFD97369),
  );

  @override
  AppColors copyWith({
    Color? navy,
    Color? orange,
    Color? background,
    Color? surface,
    Color? success,
    Color? error,
    Color? warning,
    Color? puzzleCell,
    Color? puzzleCellSelected,
    Color? puzzleWordSelected,
    Color? puzzleBlocked,
    Color? puzzleCorrect,
    Color? puzzleWrong,
  }) => AppColors(
    navy: navy ?? this.navy,
    orange: orange ?? this.orange,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    success: success ?? this.success,
    error: error ?? this.error,
    warning: warning ?? this.warning,
    puzzleCell: puzzleCell ?? this.puzzleCell,
    puzzleCellSelected: puzzleCellSelected ?? this.puzzleCellSelected,
    puzzleWordSelected: puzzleWordSelected ?? this.puzzleWordSelected,
    puzzleBlocked: puzzleBlocked ?? this.puzzleBlocked,
    puzzleCorrect: puzzleCorrect ?? this.puzzleCorrect,
    puzzleWrong: puzzleWrong ?? this.puzzleWrong,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      navy: Color.lerp(navy, other.navy, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      puzzleCell: Color.lerp(puzzleCell, other.puzzleCell, t)!,
      puzzleCellSelected: Color.lerp(
        puzzleCellSelected,
        other.puzzleCellSelected,
        t,
      )!,
      puzzleWordSelected: Color.lerp(
        puzzleWordSelected,
        other.puzzleWordSelected,
        t,
      )!,
      puzzleBlocked: Color.lerp(puzzleBlocked, other.puzzleBlocked, t)!,
      puzzleCorrect: Color.lerp(puzzleCorrect, other.puzzleCorrect, t)!,
      puzzleWrong: Color.lerp(puzzleWrong, other.puzzleWrong, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  /// Falls back to [AppColors.light] rather than throwing when no
  /// `MaterialApp` `theme` registered the extension — real screens
  /// always go through `AppTheme.light`/`dark` (see `main.dart`), which
  /// do register it, but an isolated widget test that builds its own
  /// bare `MaterialApp` (no `theme:` at all) would otherwise crash on a
  /// null-check for a reason that has nothing to do with what that test
  /// is actually checking. A real bug already found this exact gap once
  /// (see CLAUDE.MD's "Kelime Bulmacası" section) — falling back here
  /// avoids the whole class of it, at zero cost to the real app.
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
