import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/entities/word/word_clue.dart';
import 'package:nonogram_daily/domain/entities/word/word_puzzle_section.dart';

void main() {
  group('WordPuzzleSection.isCompleteGiven', () {
    final section = WordPuzzleSection(
      trackId: 'tarih',
      index: 1,
      clues: [
        WordClue(id: 'c1', text: 'clue one', answer: 'fatih'),
        WordClue(id: 'c2', text: 'clue two', answer: 'osman'),
      ],
    );

    test('false when no clues are solved', () {
      expect(section.isCompleteGiven(<String>{}), isFalse);
    });

    test('false when only some clues are solved', () {
      expect(section.isCompleteGiven({'c1'}), isFalse);
    });

    test('true only once every clue id in the section is solved', () {
      expect(section.isCompleteGiven({'c1', 'c2'}), isTrue);
    });

    test('unrelated solved ids from other sections do not count', () {
      expect(section.isCompleteGiven({'c1', 'unrelated-clue'}), isFalse);
    });
  });
}
