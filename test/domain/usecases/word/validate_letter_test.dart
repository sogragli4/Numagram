import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/entities/word/word_clue.dart';
import 'package:nonogram_daily/domain/usecases/word/validate_letter.dart';

void main() {
  group('validateLetter', () {
    final clue = WordClue(
      id: '1',
      text: "İstanbul'u fetheden padişah",
      answer: 'fatih',
    );

    test('a correct letter fills the position and is not yet solved', () {
      final result = validateLetter(
        clue: clue,
        currentLetters: List<String?>.filled(5, null),
        position: 0,
        typedLetter: 'f',
      );

      expect(result.correct, isTrue);
      expect(result.updatedLetters, ['F', null, null, null, null]);
      expect(result.clueSolved, isFalse);
    });

    test(
      'a wrong letter leaves the letters array unchanged, no heart cost',
      () {
        final current = List<String?>.filled(5, null);
        final result = validateLetter(
          clue: clue,
          currentLetters: current,
          position: 0,
          typedLetter: 'x',
        );

        expect(result.correct, isFalse);
        expect(result.updatedLetters, current);
        expect(result.clueSolved, isFalse);
      },
    );

    test('the final correct letter marks the clue solved', () {
      final result = validateLetter(
        clue: clue,
        currentLetters: ['F', 'A', 'T', 'İ', null],
        position: 4,
        typedLetter: 'h',
      );

      expect(result.correct, isTrue);
      expect(result.updatedLetters, ['F', 'A', 'T', 'İ', 'H']);
      expect(result.clueSolved, isTrue);
    });

    test(
      'Turkish dotted/dotless i is checked correctly, not via plain toUpperCase',
      () {
        // "FATİH" has a dotted İ at index 3 — typing lowercase 'i' must match
        // it (Turkish uppercase of 'i' is 'İ'), and typing 'ı' must not.
        final matchesDottedI = validateLetter(
          clue: clue,
          currentLetters: ['F', 'A', 'T', null, null],
          position: 3,
          typedLetter: 'i',
        );
        expect(matchesDottedI.correct, isTrue);

        final dotlessIDoesNotMatch = validateLetter(
          clue: clue,
          currentLetters: ['F', 'A', 'T', null, null],
          position: 3,
          typedLetter: 'ı',
        );
        expect(dotlessIDoesNotMatch.correct, isFalse);
      },
    );

    test(
      'typed letter case does not matter for an already-uppercase answer',
      () {
        final result = validateLetter(
          clue: clue,
          currentLetters: List<String?>.filled(5, null),
          position: 0,
          typedLetter: 'F',
        );
        expect(result.correct, isTrue);
      },
    );
  });
}
