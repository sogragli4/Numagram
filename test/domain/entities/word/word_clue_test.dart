import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/entities/word/word_clue.dart';

void main() {
  group('WordClue', () {
    test('normalizes the answer to Turkish uppercase on construction', () {
      final clue = WordClue(
        id: '1',
        text: "İstanbul'u fetheden padişah",
        answer: 'fatih',
      );
      expect(clue.answer, 'FATİH');
    });

    test('length matches the normalized answer length, not the raw input', () {
      final clue = WordClue(id: '1', text: 'clue', answer: 'ısırgan');
      expect(clue.length, 7);
    });

    test('equality is value-based', () {
      final a = WordClue(id: '1', text: 'clue', answer: 'fatih');
      final b = WordClue(id: '1', text: 'clue', answer: 'FATİH');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different id makes clues unequal even with the same text/answer', () {
      final a = WordClue(id: '1', text: 'clue', answer: 'fatih');
      final b = WordClue(id: '2', text: 'clue', answer: 'fatih');
      expect(a, isNot(b));
    });
  });
}
