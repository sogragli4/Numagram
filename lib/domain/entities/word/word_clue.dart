import 'package:meta/meta.dart';
import 'package:nonogram_daily/core/turkish_text.dart';

/// A single clue-and-answer pair — e.g. "İstanbul'u fetheden padişah" →
/// "FATİH". [answer] is stored pre-normalized to Turkish-locale uppercase
/// (see `toTurkishUpperCase`) so every comparison against it is a plain
/// string equality, never a repeated casing step.
@immutable
class WordClue {
  WordClue({required this.id, required this.text, required String answer})
    : answer = toTurkishUpperCase(answer);

  final String id;
  final String text;
  final String answer;

  int get length => answer.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordClue &&
          id == other.id &&
          text == other.text &&
          answer == other.answer);

  @override
  int get hashCode => Object.hash(id, text, answer);
}
