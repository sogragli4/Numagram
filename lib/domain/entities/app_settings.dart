/// Persisted user preferences.
class AppSettings {
  const AppSettings({
    required this.notificationHour,
    required this.notificationMinute,
    required this.notificationsEnabled,
    required this.colorblindPalette,
    required this.hasCompletedFirstPuzzle,
    required this.sessionCount,
    required this.lastKnownStreak,
    required this.archiveUnlocksDateKey,
    required this.archiveUnlocksCount,
    required this.selectedThemeId,
    required this.hasSeenTutorial,
    required this.soundEnabled,
  });

  static const defaults = AppSettings(
    notificationHour: 9,
    notificationMinute: 0,
    notificationsEnabled: false,
    colorblindPalette: false,
    hasCompletedFirstPuzzle: false,
    sessionCount: 0,
    lastKnownStreak: 0,
    archiveUnlocksDateKey: null,
    archiveUnlocksCount: 0,
    selectedThemeId: 'classic',
    hasSeenTutorial: false,
    soundEnabled: true,
  );

  /// Default daily-reminder time, per the Phase 3 spec.
  final int notificationHour;
  final int notificationMinute;

  /// Whether the daily reminder is actually scheduled. Notification
  /// permission — and this flag — are only ever turned on after the
  /// player completes their first puzzle, never on launch.
  final bool notificationsEnabled;

  final bool colorblindPalette;
  final bool hasCompletedFirstPuzzle;

  /// Incremented once per cold start. Phase 4's interstitial rule
  /// ("never during the first session ever") reads this as `> 1`.
  final int sessionCount;

  /// The current streak the last time it was observed, so the app can
  /// detect a `streak_broken` transition (was > 0, now 0) for Analytics
  /// without re-deriving history.
  final int lastKnownStreak;

  /// `yyyy-MM-dd` the day [archiveUnlocksCount] applies to; `null` before
  /// the player has ever opened an archive puzzle. A different key than
  /// "today" means the count has implicitly reset — see
  /// [archiveUnlocksCountFor].
  final String? archiveUnlocksDateKey;
  final int archiveUnlocksCount;

  /// Which unlockable colour theme is selected — matches
  /// `AppColorTheme.id` (`core/theme.dart`). A plain string, not the enum
  /// itself: domain entities don't depend on Flutter (which `Color` is
  /// part of), so the enum has to live in the presentation-adjacent
  /// `core/theme.dart` instead.
  final String selectedThemeId;

  /// Whether the player has completed (or skipped) the interactive
  /// "how to play" tutorial at least once. Shown automatically before the
  /// very first puzzle, and replayable from Settings afterward.
  final bool hasSeenTutorial;

  /// Whether gameplay SFX (fill/mark/mistake/win) play. Independent of
  /// haptics — a player may want one without the other.
  final bool soundEnabled;

  /// Archive puzzles already opened on [todayKey] — 0 if that's not the
  /// date [archiveUnlocksCount] was tracking (i.e. the day rolled over).
  int archiveUnlocksCountFor(String todayKey) =>
      archiveUnlocksDateKey == todayKey ? archiveUnlocksCount : 0;

  AppSettings copyWith({
    int? notificationHour,
    int? notificationMinute,
    bool? notificationsEnabled,
    bool? colorblindPalette,
    bool? hasCompletedFirstPuzzle,
    int? sessionCount,
    int? lastKnownStreak,
    String? Function()? archiveUnlocksDateKey,
    int? archiveUnlocksCount,
    String? selectedThemeId,
    bool? hasSeenTutorial,
    bool? soundEnabled,
  }) => AppSettings(
    notificationHour: notificationHour ?? this.notificationHour,
    notificationMinute: notificationMinute ?? this.notificationMinute,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    colorblindPalette: colorblindPalette ?? this.colorblindPalette,
    hasCompletedFirstPuzzle:
        hasCompletedFirstPuzzle ?? this.hasCompletedFirstPuzzle,
    sessionCount: sessionCount ?? this.sessionCount,
    lastKnownStreak: lastKnownStreak ?? this.lastKnownStreak,
    archiveUnlocksDateKey: archiveUnlocksDateKey != null
        ? archiveUnlocksDateKey()
        : this.archiveUnlocksDateKey,
    archiveUnlocksCount: archiveUnlocksCount ?? this.archiveUnlocksCount,
    selectedThemeId: selectedThemeId ?? this.selectedThemeId,
    hasSeenTutorial: hasSeenTutorial ?? this.hasSeenTutorial,
    soundEnabled: soundEnabled ?? this.soundEnabled,
  );
}
