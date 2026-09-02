import 'package:isar_community/isar.dart';
import 'package:nonogram_daily/core/date_key.dart';
import 'package:nonogram_daily/domain/entities/difficulty.dart';
import 'package:nonogram_daily/domain/entities/grid_size.dart';
import 'package:nonogram_daily/domain/entities/puzzle_completion.dart';

part 'puzzle_completion_model.g.dart';

/// Isar collection backing `StreakRepository`. Only ever stores the *fact*
/// that a puzzle was completed, never the puzzle itself — the archive is
/// zero-storage by design (Phase 3 spec), since any puzzle regenerates
/// deterministically from its seed.
@collection
class PuzzleCompletionModel {
  PuzzleCompletionModel();

  factory PuzzleCompletionModel.fromEntity(PuzzleCompletion entity) =>
      PuzzleCompletionModel()
        ..dateKey = entity.date == null ? null : formatDateKey(entity.date!)
        ..width = entity.size.width
        ..height = entity.size.height
        ..difficulty = entity.difficulty.name
        ..elapsedSeconds = entity.elapsedSeconds
        ..mistakeCount = entity.mistakeCount
        ..completedAt = entity.completedAt;

  Id id = Isar.autoIncrement;

  /// `yyyy-MM-dd`, or `null` for a free-play completion (which doesn't
  /// count toward the streak).
  ///
  /// Not a unique index: multiple free-play rows share `null`, and
  /// "one row per daily date" is enforced by the repository (check before
  /// insert) rather than the schema, since Isar unique-index semantics for
  /// repeated `null` values aren't worth relying on here.
  @Index()
  String? dateKey;

  late int width;
  late int height;
  late String difficulty;
  late int elapsedSeconds;
  late int mistakeCount;
  late DateTime completedAt;

  PuzzleCompletion toEntity() => PuzzleCompletion(
    date: dateKey == null ? null : parseDateKey(dateKey!),
    size: GridSize(width, height),
    difficulty: Difficulty.values.byName(difficulty),
    elapsedSeconds: elapsedSeconds,
    mistakeCount: mistakeCount,
    completedAt: completedAt,
  );
}
