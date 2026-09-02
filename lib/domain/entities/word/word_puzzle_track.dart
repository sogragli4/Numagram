import 'package:meta/meta.dart';

/// The six launch categories (CLAUDE.MD, "Kelime Bulmacası" bölüm 5).
/// [zKusagi] is the one that branches into named sub-tracks — see
/// [WordPuzzleTrack.subBranchLabel].
enum WordTrackCategory { tarih, genelKultur, hukuk, gundem, zKusagi, karisik }

/// A single progression chain — either a flat category (e.g. "Tarih") or
/// one of Z Kuşağı's five sub-branches (e.g. "Z Kuşağı → İnternet
/// Kültürü"). Advances as numbered `WordPuzzleSection`s: "Tarih 1, Tarih
/// 2, ...". Every track other than [WordTrackCategory.zKusagi] has
/// [subBranchLabel] `null` — branching only that one category is a
/// deliberate launch scope decision, not a technical limitation.
@immutable
class WordPuzzleTrack {
  const WordPuzzleTrack({
    required this.id,
    required this.category,
    this.subBranchLabel,
  });

  /// Stable identifier, e.g. `"tarih"` or `"z_kusagi_internet_kulturu"`.
  final String id;
  final WordTrackCategory category;

  /// The sub-branch display name for a Z Kuşağı track (e.g. "İnternet
  /// Kültürü"), or `null` for every other, flat track.
  final String? subBranchLabel;

  bool get isBranched => subBranchLabel != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordPuzzleTrack &&
          id == other.id &&
          category == other.category &&
          subBranchLabel == other.subBranchLabel);

  @override
  int get hashCode => Object.hash(id, category, subBranchLabel);
}
