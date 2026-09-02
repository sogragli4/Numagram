import 'package:isar_community/isar.dart';
import 'package:nonogram_daily/domain/entities/word/word_progress.dart';

part 'word_progress_model.g.dart';

/// Single-row word-progress table — always stored at [fixedId], so
/// there's exactly one record per install, mirroring
/// `AppSettingsModel`'s pattern exactly.
@collection
class WordProgressModel {
  WordProgressModel();

  factory WordProgressModel.fromEntity(WordProgress entity) =>
      WordProgressModel()
        ..id = fixedId
        ..completedSectionKeys = entity.completedSectionKeys.toList()
        ..interestTagIds = entity.interestTagIds.toList()
        ..hasSeenInterestSurvey = entity.hasSeenInterestSurvey
        ..categoryChangeDateKey = entity.categoryChangeDateKey
        ..categoryChangeCount = entity.categoryChangeCount;

  static const int fixedId = 0;

  Id id = fixedId;

  List<String> completedSectionKeys = [];
  List<String> interestTagIds = [];
  bool hasSeenInterestSurvey = false;
  String? categoryChangeDateKey;
  int categoryChangeCount = 0;

  WordProgress toEntity() => WordProgress(
    completedSectionKeys: completedSectionKeys.toSet(),
    interestTagIds: interestTagIds.toSet(),
    hasSeenInterestSurvey: hasSeenInterestSurvey,
    categoryChangeDateKey: categoryChangeDateKey,
    categoryChangeCount: categoryChangeCount,
  );
}
