import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/entities/word/word_puzzle_track.dart';

void main() {
  group('WordPuzzleTrack', () {
    test('a flat category track has no sub-branch label', () {
      const track = WordPuzzleTrack(
        id: 'tarih',
        category: WordTrackCategory.tarih,
      );
      expect(track.isBranched, isFalse);
      expect(track.subBranchLabel, isNull);
    });

    test('a Z Kuşağı sub-branch track is branched', () {
      const track = WordPuzzleTrack(
        id: 'z_kusagi_internet_kulturu',
        category: WordTrackCategory.zKusagi,
        subBranchLabel: 'İnternet Kültürü',
      );
      expect(track.isBranched, isTrue);
    });

    test('equality is value-based', () {
      const a = WordPuzzleTrack(id: 'tarih', category: WordTrackCategory.tarih);
      const b = WordPuzzleTrack(id: 'tarih', category: WordTrackCategory.tarih);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
