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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InterestProfile &&
          selectedTagIds.length == other.selectedTagIds.length &&
          selectedTagIds.containsAll(other.selectedTagIds));

  @override
  int get hashCode => Object.hashAll(selectedTagIds.toList()..sort());
}
