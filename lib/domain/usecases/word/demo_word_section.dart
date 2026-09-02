import 'package:nonogram_daily/domain/entities/word/word_clue.dart';
import 'package:nonogram_daily/domain/entities/word/word_puzzle_section.dart';

/// A fixed, hand-authored section used to scaffold the word-board screen
/// before Faz 3's content pipeline (real, reviewed clue sets bundled per
/// track) exists — the word-game equivalent of Nonogram's own Phase 2
/// "fixed-seed demo puzzle generated inline in `BoardController.build()`"
/// scaffolding, kept here instead as its own function so it's easy to
/// find and delete once real content lands.
///
/// Deliberately avoids contested historical claims (unlike a real Tarih
/// track would eventually need — see CLAUDE.MD's content-review
/// decision): every clue here is a safely uncontroversial fact, since
/// this is placeholder-not-shipped content, not reviewed Tarih content.
WordPuzzleSection buildDemoWordSection() => WordPuzzleSection(
  trackId: 'demo',
  index: 1,
  clues: [
    WordClue(
      id: 'demo-1',
      text: "İstanbul'u fetheden padişah",
      answer: 'fatih',
    ),
    WordClue(
      id: 'demo-2',
      text: "Türkiye Cumhuriyeti'nin başkenti",
      answer: 'ankara',
    ),
    WordClue(
      id: 'demo-3',
      text: "Türkiye'nin en kalabalık şehri",
      answer: 'istanbul',
    ),
    WordClue(
      id: 'demo-4',
      text: "Türkiye'nin para birimi (kısaca)",
      answer: 'lira',
    ),
  ],
);
