import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/entities/word/crossword_entry.dart';

void main() {
  group('CrosswordEntry.cellAt', () {
    test('an across entry advances column, holds row', () {
      final entry = CrosswordEntry(
        id: '1',
        clueNumber: 1,
        direction: CrosswordDirection.across,
        startRow: 2,
        startCol: 3,
        clueText: 'clue',
        answer: 'kitap',
      );
      expect(entry.cellAt(0), (2, 3));
      expect(entry.cellAt(4), (2, 7));
    });

    test('a down entry advances row, holds column', () {
      final entry = CrosswordEntry(
        id: '1',
        clueNumber: 1,
        direction: CrosswordDirection.down,
        startRow: 2,
        startCol: 3,
        clueText: 'clue',
        answer: 'kuş',
      );
      expect(entry.cellAt(0), (2, 3));
      expect(entry.cellAt(2), (4, 3));
    });

    test('answer is normalized to Turkish uppercase, length matches it', () {
      final entry = CrosswordEntry(
        id: '1',
        clueNumber: 1,
        direction: CrosswordDirection.across,
        startRow: 0,
        startCol: 0,
        clueText: 'clue',
        answer: 'kitap',
      );
      expect(entry.answer, 'KİTAP');
      expect(entry.length, 5);
    });
  });
}
