import 'package:nonogram_daily/domain/entities/word/word_session.dart';
import 'package:nonogram_daily/domain/usecases/word/demo_word_section.dart';
import 'package:nonogram_daily/domain/usecases/word/validate_letter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'word_board_controller.g.dart';

class WordBoardState {
  const WordBoardState({
    required this.session,
    required this.wrongFlashClueId,
    required this.wrongFlashPosition,
    required this.wrongFlashToken,
  });

  final WordSession session;

  /// The most recent wrong-letter box, plus a token that increments on
  /// every wrong letter so the UI can restart the flash animation even
  /// if the same box is mistyped twice in a row — same pattern as
  /// `BoardState.wrongFlashRow`/`wrongFlashCol`/`wrongFlashToken`.
  final String? wrongFlashClueId;
  final int? wrongFlashPosition;
  final int wrongFlashToken;

  WordBoardState copyWith({
    WordSession? session,
    String? Function()? wrongFlashClueId,
    int? Function()? wrongFlashPosition,
    int? wrongFlashToken,
  }) => WordBoardState(
    session: session ?? this.session,
    wrongFlashClueId: wrongFlashClueId != null
        ? wrongFlashClueId()
        : this.wrongFlashClueId,
    wrongFlashPosition: wrongFlashPosition != null
        ? wrongFlashPosition()
        : this.wrongFlashPosition,
    wrongFlashToken: wrongFlashToken ?? this.wrongFlashToken,
  );
}

/// Drives one `WordSession` through typed-letter input. Plays a fixed
/// `buildDemoWordSection()` section — Faz 2 scaffolding only, same
/// "explicitly temporary" status Nonogram's own `BoardController` had in
/// its Phase 2, before Phase 3 wired in a real repository-backed puzzle.
@riverpod
class WordBoardController extends _$WordBoardController {
  @override
  WordBoardState build() => WordBoardState(
    session: WordSession.start(buildDemoWordSection()),
    wrongFlashClueId: null,
    wrongFlashPosition: null,
    wrongFlashToken: 0,
  );

  void typeLetter({
    required String clueId,
    required int position,
    required String letter,
  }) {
    if (state.session.won) return;

    final clue = state.session.section.clues.firstWhere((c) => c.id == clueId);
    final current = state.session.lettersByClueId[clueId]!;
    final result = validateLetter(
      clue: clue,
      currentLetters: current,
      position: position,
      typedLetter: letter,
    );

    if (!result.correct) {
      state = state.copyWith(
        wrongFlashClueId: () => clueId,
        wrongFlashPosition: () => position,
        wrongFlashToken: state.wrongFlashToken + 1,
      );
      return;
    }

    final updatedLetters = Map<String, List<String?>>.of(
      state.session.lettersByClueId,
    )..[clueId] = result.updatedLetters;
    state = state.copyWith(
      session: state.session.copyWith(lettersByClueId: updatedLetters),
    );
  }
}
