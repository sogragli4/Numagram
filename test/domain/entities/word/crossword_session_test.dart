import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/entities/word/crossword_session.dart';
import 'package:nonogram_daily/domain/usecases/word/demo_crossword.dart';

void main() {
  final puzzle = buildDemoCrossword();

  group('CrosswordSession.start', () {
    test('starts with no typed letters and is not won', () {
      final session = CrosswordSession.start(puzzle);
      expect(session.typedLetters, isEmpty);
      expect(session.won, isFalse);
    });
  });

  group('CrosswordSession.isEntrySolved / won', () {
    test('an entry with a missing cell is not solved', () {
      final session = CrosswordSession.start(puzzle).copyWith(
        typedLetters: {(0, 0): 'K', (0, 1): 'İ', (0, 2): 'T', (0, 3): 'A'},
      );
      expect(session.isEntrySolved(puzzle.entries.first), isFalse);
    });

    test(
      'solving the shared cell counts toward both the across and down entry',
      () {
        final session = CrosswordSession.start(
          puzzle,
        ).copyWith(typedLetters: {(0, 0): 'K', (1, 0): 'U', (2, 0): 'Ş'});
        final kusEntry = puzzle.entries.firstWhere((e) => e.id == 'down-1');
        expect(session.isEntrySolved(kusEntry), isTrue);
      },
    );

    test('won only once every entry in the puzzle is solved', () {
      final allLetters = <(int, int), String>{};
      for (final entry in puzzle.entries) {
        for (var i = 0; i < entry.length; i++) {
          allLetters[entry.cellAt(i)] = entry.answer[i];
        }
      }
      final session = CrosswordSession.start(
        puzzle,
      ).copyWith(typedLetters: allLetters);
      expect(session.won, isTrue);
    });
  });
}
