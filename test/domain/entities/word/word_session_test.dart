import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/entities/word/word_clue.dart';
import 'package:nonogram_daily/domain/entities/word/word_puzzle_section.dart';
import 'package:nonogram_daily/domain/entities/word/word_session.dart';

void main() {
  final section = WordPuzzleSection(
    trackId: 'tarih',
    index: 1,
    clues: [
      WordClue(id: 'c1', text: 'clue one', answer: 'fatih'),
      WordClue(id: 'c2', text: 'clue two', answer: 'lira'),
    ],
  );

  group('WordSession.start', () {
    test('every clue starts with an all-empty letters array', () {
      final session = WordSession.start(section);
      expect(session.lettersByClueId['c1'], List<String?>.filled(5, null));
      expect(session.lettersByClueId['c2'], List<String?>.filled(4, null));
    });

    test('not won at the start', () {
      expect(WordSession.start(section).won, isFalse);
    });
  });

  group('WordSession.solvedClueIds / won', () {
    test('a clue with a null letter is not counted as solved', () {
      final session = WordSession.start(section).copyWith(
        lettersByClueId: {
          'c1': ['F', 'A', 'T', 'İ', null],
          'c2': [null, null, null, null],
        },
      );
      expect(session.solvedClueIds, isEmpty);
      expect(session.won, isFalse);
    });

    test('a fully-filled clue counts as solved, others do not block it', () {
      final session = WordSession.start(section).copyWith(
        lettersByClueId: {
          'c1': ['F', 'A', 'T', 'İ', 'H'],
          'c2': [null, null, null, null],
        },
      );
      expect(session.solvedClueIds, {'c1'});
      expect(session.won, isFalse);
    });

    test('won once every clue in the section is solved', () {
      final session = WordSession.start(section).copyWith(
        lettersByClueId: {
          'c1': ['F', 'A', 'T', 'İ', 'H'],
          'c2': ['L', 'İ', 'R', 'A'],
        },
      );
      expect(session.solvedClueIds, {'c1', 'c2'});
      expect(session.won, isTrue);
    });
  });
}
