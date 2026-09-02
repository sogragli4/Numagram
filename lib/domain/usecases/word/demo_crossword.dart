import 'package:nonogram_daily/domain/entities/word/crossword_entry.dart';
import 'package:nonogram_daily/domain/entities/word/crossword_puzzle.dart';

/// A small, hand-authored, hand-verified intersecting crossword —
/// scaffolding for the board screen before Faz 3's content pipeline
/// (real, reviewed grids bundled per track) exists. Every intersection
/// below was checked by hand: KİTAP's own letters (K-İ-T-A-P) are exactly
/// what each down entry's first letter must match, since content is
/// always authored, never generated (see `CrosswordPuzzle`'s doc comment
/// for why that's not a limitation here).
///
/// ```text
///   K İ T A P     (1-Across: KİTAP)
///   U   A   A
///   Ş   V   R
///       U   K
///       K
/// ```
CrosswordPuzzle buildDemoCrossword() => CrosswordPuzzle(
  trackId: 'demo',
  sectionIndex: 1,
  width: 5,
  height: 5,
  entries: [
    CrosswordEntry(
      id: 'across-1',
      clueNumber: 1,
      direction: CrosswordDirection.across,
      startRow: 0,
      startCol: 0,
      clueText: 'Sayfalardan oluşan okuma malzemesi',
      answer: 'kitap',
    ),
    CrosswordEntry(
      id: 'down-1',
      clueNumber: 1,
      direction: CrosswordDirection.down,
      startRow: 0,
      startCol: 0,
      clueText: 'Uçabilen hayvan',
      answer: 'kuş',
    ),
    CrosswordEntry(
      id: 'down-2',
      clueNumber: 2,
      direction: CrosswordDirection.down,
      startRow: 0,
      startCol: 2,
      clueText: 'Yumurtlayan çiftlik hayvanı',
      answer: 'tavuk',
    ),
    CrosswordEntry(
      id: 'down-3',
      clueNumber: 3,
      direction: CrosswordDirection.down,
      startRow: 0,
      startCol: 4,
      clueText: 'Yeşil alan, oyun bahçesi',
      answer: 'park',
    ),
  ],
);
