import 'package:nonogram_daily/domain/entities/word/word_progress.dart';

/// Persists `WordProgress` — the word game's `SettingsRepository`
/// equivalent, added in Faz 3 alongside the rest of this feature's
/// persistence layer.
abstract class WordProgressRepository {
  Future<WordProgress> getProgress();
  Future<void> updateProgress(WordProgress progress);
}
