import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/entities/word/crossword_entry.dart';
import 'package:nonogram_daily/domain/entities/word/crossword_puzzle.dart';
import 'package:nonogram_daily/domain/usecases/word/demo_crossword.dart';

void main() {
  group('demo crossword (real content, hand-verified intersections)', () {
    final puzzle = buildDemoCrossword();

    test('the shared cell of an across and a down entry agrees', () {
      // (0,0) is 1-Across (KİTAP)'s first letter and 1-Down (KUŞ)'s first
      // letter — both must be 'K'.
      expect(puzzle.solutionLetterAt(0, 0), 'K');
    });

    test('every down entry matches KİTAP at its starting column', () {
      expect(puzzle.solutionLetterAt(0, 2), 'T'); // TAVUK vs KİTAP[2]
      expect(puzzle.solutionLetterAt(0, 4), 'P'); // PARK vs KİTAP[4]
    });

    test('a cell with no entry is blocked', () {
      expect(puzzle.isBlocked(1, 1), isTrue);
      expect(puzzle.solutionLetterAt(1, 1), isNull);
    });

    test('clueNumberAt returns the shared number for a shared start cell', () {
      expect(puzzle.clueNumberAt(0, 0), 1);
      expect(puzzle.clueNumberAt(0, 2), 2);
      expect(puzzle.clueNumberAt(0, 4), 3);
    });

    test('clueNumberAt is null for a cell that is mid-entry, not a start', () {
      expect(puzzle.clueNumberAt(0, 1), isNull);
      expect(puzzle.clueNumberAt(2, 2), isNull);
    });
  });

  group('CrosswordPuzzle.solutionLetterAt', () {
    test('a cell covered by exactly one entry returns that letter', () {
      final puzzle = CrosswordPuzzle(
        trackId: 't',
        sectionIndex: 1,
        width: 3,
        height: 1,
        entries: [
          CrosswordEntry(
            id: '1',
            clueNumber: 1,
            direction: CrosswordDirection.across,
            startRow: 0,
            startCol: 0,
            clueText: 'clue',
            answer: 'kaş',
          ),
        ],
      );
      expect(puzzle.solutionLetterAt(0, 0), 'K');
      expect(puzzle.solutionLetterAt(0, 1), 'A');
      expect(puzzle.solutionLetterAt(0, 2), 'Ş');
    });
  });
}
