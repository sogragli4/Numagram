import 'package:meta/meta.dart';

/// The player's selected interest tags from the onboarding survey — their
/// personal question pool (CLAUDE.MD, "Kelime Bulmacası" bölüm 3). Only
/// re-orders/prioritizes Hikaye Modu content; never locks a track out of
/// Kategori Modu.
@immutable
class InterestProfile {
  const InterestProfile({required this.selectedTagIds});

  static const InterestProfile empty = InterestProfile(selectedTagIds: {});

  final Set<String> selectedTagIds;

  bool get isEmpty => selectedTagIds.isEmpty;

  /// Canonical tag ids offered by the onboarding survey — every flat
  /// category except `WordTrackCategory.karisik` (the always-open mixed
  /// default isn't a personal "interest" to opt into — see
  /// `WordPuzzleTrack`) plus all five Z Kuşağı sub-branches individually,
  /// matching `WordPuzzleTrack.id`'s naming scheme. Display labels live
  /// in ARB (`wordSurveyTag...`), not here — this file has no Flutter/
  /// l10n dependency.
  static const allTagIds = [
    'tarih',
    'genel_kultur',
    'hukuk',
    'gundem',
    'z_kusagi',
    'z_kusagi_internet_kulturu',
    'z_kusagi_dizi_sinema',
    'z_kusagi_muzik_trendler',
    'z_kusagi_oyun_kulturu',
    'z_kusagi_sosyal_medya_gundemi',
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InterestProfile &&
          selectedTagIds.length == other.selectedTagIds.length &&
          selectedTagIds.containsAll(other.selectedTagIds));

  @override
  int get hashCode => Object.hashAll(selectedTagIds.toList()..sort());
}
