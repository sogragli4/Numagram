import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/usecases/word/demo_crossword.dart';
import 'package:nonogram_daily/domain/usecases/word/validate_crossword_letter.dart';

void main() {
  group('validateCrosswordLetter', () {
    final puzzle = buildDemoCrossword();

    test('a correct letter is written into the map at that cell', () {
      final result = validateCrosswordLetter(
        puzzle: puzzle,
        currentLetters: const {},
        row: 0,
        col: 0,
        typedLetter: 'k',
      );
      expect(result.correct, isTrue);
      expect(result.updatedLetters, {(0, 0): 'K'});
    });

    test('a wrong letter leaves the map unchanged, no heart cost', () {
      const current = {(0, 0): 'K'};
      final result = validateCrosswordLetter(
        puzzle: puzzle,
        currentLetters: current,
        row: 0,
        col: 1,
        typedLetter: 'x',
      );
      expect(result.correct, isFalse);
      expect(result.updatedLetters, current);
    });

    test('an intersecting cell accepts the letter shared by both entries', () {
      // (0,2) is both KİTAP's 3rd letter and TAVUK's 1st letter — both are
      // 'T', so there is exactly one correct answer for that cell.
      final result = validateCrosswordLetter(
        puzzle: puzzle,
        currentLetters: const {},
        row: 0,
        col: 2,
        typedLetter: 't',
      );
      expect(result.correct, isTrue);
    });

    test('typing the Turkish dotted İ correctly at a real intersection', () {
      // (0,1) is KİTAP's 2nd letter, 'İ' — dotted-i correctness matters
      // here exactly as it did for the clue-list mechanic.
      final result = validateCrosswordLetter(
        puzzle: puzzle,
        currentLetters: const {},
        row: 0,
        col: 1,
        typedLetter: 'i',
      );
      expect(result.correct, isTrue);
      expect(result.updatedLetters[(0, 1)], 'İ');
    });
  });
}
