import 'package:isar_community/isar.dart';
import 'package:nonogram_daily/core/constants.dart';
import 'package:nonogram_daily/domain/entities/app_settings.dart';

part 'app_settings_model.g.dart';

/// Single-row settings table — always stored at [fixedId], so there's
/// exactly one settings record per install.
@collection
class AppSettingsModel {
  AppSettingsModel();

  factory AppSettingsModel.fromEntity(AppSettings entity) => AppSettingsModel()
    ..id = fixedId
    ..notificationHour = entity.notificationHour
    ..notificationMinute = entity.notificationMinute
    ..notificationsEnabled = entity.notificationsEnabled
    ..colorblindPalette = entity.colorblindPalette
    ..hasCompletedFirstPuzzle = entity.hasCompletedFirstPuzzle
    ..sessionCount = entity.sessionCount
    ..lastKnownStreak = entity.lastKnownStreak
    ..archiveUnlocksDateKey = entity.archiveUnlocksDateKey
    ..archiveUnlocksCount = entity.archiveUnlocksCount
    ..selectedThemeId = entity.selectedThemeId
    ..hasSeenTutorial = entity.hasSeenTutorial
    ..soundEnabled = entity.soundEnabled
    ..streakFreezesAvailable = entity.streakFreezesAvailable
    ..frozenDateKeys = entity.frozenDateKeys
    ..freezeGrantMonthKey = entity.freezeGrantMonthKey;

  static const int fixedId = 0;

  Id id = fixedId;

  late int notificationHour;
  late int notificationMinute;
  late bool notificationsEnabled;
  late bool colorblindPalette;
  late bool hasCompletedFirstPuzzle;
  late int sessionCount;
  late int lastKnownStreak;
  String? archiveUnlocksDateKey;
  late int archiveUnlocksCount;
  // Non-late with a default: an existing local install from before this
  // field existed still reads back a sane value instead of crashing.
  String selectedThemeId = 'classic';
  // Same reasoning: an existing install predates this field, and should
  // see the tutorial once rather than crash on read.
  bool hasSeenTutorial = false;
  // Same reasoning again: an existing install predates this field too —
  // default to sound on, matching `AppSettings.defaults`.
  bool soundEnabled = true;
  // Same reasoning again: an existing install predates the streak-freeze
  // feature, so it reads back as if freshly starting it.
  int streakFreezesAvailable = StreakFreezeConfig.startingFreezes;
  List<String> frozenDateKeys = [];
  String? freezeGrantMonthKey;

  AppSettings toEntity() => AppSettings(
    notificationHour: notificationHour,
    notificationMinute: notificationMinute,
    notificationsEnabled: notificationsEnabled,
    colorblindPalette: colorblindPalette,
    hasCompletedFirstPuzzle: hasCompletedFirstPuzzle,
    sessionCount: sessionCount,
    lastKnownStreak: lastKnownStreak,
    archiveUnlocksDateKey: archiveUnlocksDateKey,
    archiveUnlocksCount: archiveUnlocksCount,
    selectedThemeId: selectedThemeId,
    hasSeenTutorial: hasSeenTutorial,
    soundEnabled: soundEnabled,
    streakFreezesAvailable: streakFreezesAvailable,
    frozenDateKeys: frozenDateKeys,
    freezeGrantMonthKey: freezeGrantMonthKey,
  );
}
