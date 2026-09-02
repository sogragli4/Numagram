import 'package:nonogram_daily/domain/entities/word/crossword_entry.dart';
import 'package:nonogram_daily/domain/entities/word/crossword_session.dart';
import 'package:nonogram_daily/domain/usecases/word/demo_crossword.dart';
import 'package:nonogram_daily/domain/usecases/word/validate_crossword_letter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'word_board_controller.g.dart';

class WordBoardState {
  const WordBoardState({
    required this.session,
    required this.activeEntry,
    required this.activeCell,
    required this.mistakeCount,
    required this.wrongFlashCell,
    required this.wrongFlashToken,
  });

  final CrosswordSession session;

  /// The entry the on-screen keyboard currently types into — never
  /// `null` once the board has loaded (there's always at least one
  /// entry), so screens don't need to null-check it on every build.
  final CrosswordEntry activeEntry;

  /// The `(row, col)` the next typed letter lands on, within
  /// [activeEntry].
  final (int, int) activeCell;

  /// How many wrong letters this session has typed so far — a stat, not
  /// a fail-state: see CLAUDE.MD's "no heart cost" decision. Shown in
  /// the toolbar the way Nonogram shows hearts, but never ends the game.
  final int mistakeCount;

  /// The most recent wrong-letter cell, plus a token that increments on
  /// every wrong letter so the UI can restart the flash animation even
  /// if the same cell is mistyped twice in a row — same pattern as
  /// `BoardState.wrongFlashRow`/`wrongFlashCol`/`wrongFlashToken`.
  final (int, int)? wrongFlashCell;
  final int wrongFlashToken;

  WordBoardState copyWith({
    CrosswordSession? session,
    CrosswordEntry? activeEntry,
    (int, int)? activeCell,
    int? mistakeCount,
    (int, int)? Function()? wrongFlashCell,
    int? wrongFlashToken,
  }) => WordBoardState(
    session: session ?? this.session,
    activeEntry: activeEntry ?? this.activeEntry,
    activeCell: activeCell ?? this.activeCell,
    mistakeCount: mistakeCount ?? this.mistakeCount,
    wrongFlashCell: wrongFlashCell != null
        ? wrongFlashCell()
        : this.wrongFlashCell,
    wrongFlashToken: wrongFlashToken ?? this.wrongFlashToken,
  );
}

/// Drives one `CrosswordSession` through the on-screen keyboard. Plays a
/// fixed `buildDemoCrossword()` puzzle — Faz 2 scaffolding only, same
/// "explicitly temporary" status Nonogram's own `BoardController` had in
/// its Phase 2, before Phase 3 wired in a real repository-backed puzzle.
@riverpod
class WordBoardController extends _$WordBoardController {
  @override
  WordBoardState build() {
    final session = CrosswordSession.start(buildDemoCrossword());
    final firstEntry = session.puzzle.entries.first;
    return WordBoardState(
      session: session,
      activeEntry: firstEntry,
      activeCell: firstEntry.cellAt(0),
      mistakeCount: 0,
      wrongFlashCell: null,
      wrongFlashToken: 0,
    );
  }

  /// Switches the active entry — tapping a clue in the YATAY/DİKEY lists,
  /// or tapping a cell that belongs to a different entry than the one
  /// currently active.
  void selectEntry(CrosswordEntry entry, {(int, int)? atCell}) {
    state = state.copyWith(
      activeEntry: entry,
      activeCell: atCell ?? _firstEmptyCell(entry),
    );
  }

  void typeLetter(String letter) {
    if (state.session.won) return;

    final (row, col) = state.activeCell;
    final result = validateCrosswordLetter(
      puzzle: state.session.puzzle,
      currentLetters: state.session.typedLetters,
      row: row,
      col: col,
      typedLetter: letter,
    );

    if (!result.correct) {
      state = state.copyWith(
        mistakeCount: state.mistakeCount + 1,
        wrongFlashCell: () => (row, col),
        wrongFlashToken: state.wrongFlashToken + 1,
      );
      return;
    }

    final session = state.session.copyWith(typedLetters: result.updatedLetters);
    state = state.copyWith(session: session, activeCell: _advance(session));
  }

  /// Clears every letter this session has typed for the active entry
  /// alone — a shared (intersecting) letter stays if the *other* entry
  /// through it is still relying on it.
  void clearActiveEntry() {
    final entry = state.activeEntry;
    final updated = Map<(int, int), String>.of(state.session.typedLetters);
    for (var i = 0; i < entry.length; i++) {
      updated.remove(entry.cellAt(i));
    }
    state = state.copyWith(
      session: state.session.copyWith(typedLetters: updated),
      activeCell: entry.cellAt(0),
    );
  }

  (int, int) _firstEmptyCell(CrosswordEntry entry) {
    for (var i = 0; i < entry.length; i++) {
      final cell = entry.cellAt(i);
      if (state.session.typedLetters[cell] == null) return cell;
    }
    return entry.cellAt(0);
  }

  /// After a correct letter: the next empty cell in the same entry, or —
  /// once that entry is fully solved — the first empty cell of the next
  /// unsolved entry, so a player only ever needs to tap once to start.
  (int, int) _advance(CrosswordSession session) {
    final entry = state.activeEntry;
    for (var i = 0; i < entry.length; i++) {
      final cell = entry.cellAt(i);
      if (session.typedLetters[cell] == null) return cell;
    }

    for (final candidate in session.puzzle.entries) {
      if (!session.isEntrySolved(candidate)) {
        state = state.copyWith(activeEntry: candidate);
        return _firstEmptyCellIn(candidate, session);
      }
    }
    return entry.cellAt(entry.length - 1);
  }

  (int, int) _firstEmptyCellIn(CrosswordEntry entry, CrosswordSession session) {
    for (var i = 0; i < entry.length; i++) {
      final cell = entry.cellAt(i);
      if (session.typedLetters[cell] == null) return cell;
    }
    return entry.cellAt(0);
  }
}
