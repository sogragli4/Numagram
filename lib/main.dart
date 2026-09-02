import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:nonogram_daily/core/constants.dart';
import 'package:nonogram_daily/core/date_key.dart';
import 'package:nonogram_daily/core/injection.dart';
import 'package:nonogram_daily/core/l10n_gen/app_localizations.dart';
import 'package:nonogram_daily/core/theme.dart';
import 'package:nonogram_daily/data/datasources/isar_local_data_source.dart';
import 'package:nonogram_daily/data/models/app_settings_model.dart';
import 'package:nonogram_daily/data/models/puzzle_completion_model.dart';
import 'package:nonogram_daily/data/repositories/settings_repository_impl.dart';
import 'package:nonogram_daily/data/repositories/streak_repository_impl.dart';
import 'package:nonogram_daily/domain/usecases/streak_freeze.dart';
import 'package:nonogram_daily/presentation/consent/consent_gate.dart';
import 'package:nonogram_daily/presentation/daily/daily_screen.dart';
import 'package:nonogram_daily/presentation/onboarding/tutorial_screen.dart';
import 'package:nonogram_daily/presentation/settings/settings_controller.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final directory = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([
    PuzzleCompletionModelSchema,
    AppSettingsModelSchema,
  ], directory: directory.path);

  final dataSource = IsarLocalDataSource(isar);
  final settingsRepository = SettingsRepositoryImpl(dataSource);
  final loadedSettings = await settingsRepository.getSettings();

  // Streak freeze: check for a new monthly grant, then whether yesterday
  // needs auto-freezing to protect an in-progress streak — both derived
  // fresh at cold start rather than tracked incrementally, same
  // "recompute from source data" reasoning as StreakRecord itself.
  final today = DateTime.now();
  final todayMonthKey = formatMonthKey(today);
  var freezesAvailable = loadedSettings.streakFreezesAvailable;
  var freezeGrantMonthKey = loadedSettings.freezeGrantMonthKey;
  if (isNewMonthlyFreezeGrantDue(
    todayMonthKey: todayMonthKey,
    lastGrantMonthKey: freezeGrantMonthKey,
  )) {
    freezesAvailable = (freezesAvailable + StreakFreezeConfig.monthlyGrant)
        .clamp(0, StreakFreezeConfig.maxFreezesHeld);
    freezeGrantMonthKey = todayMonthKey;
  }

  var frozenDateKeys = loadedSettings.frozenDateKeys;
  final completedDates = await StreakRepositoryImpl(
    dataSource,
  ).getCompletedDates();
  final frozenDates = frozenDateKeys.map(parseDateKey).toSet();
  if (shouldAutoFreezeYesterday(
    completedDates: completedDates,
    frozenDates: frozenDates,
    today: today,
    freezesAvailable: freezesAvailable,
  )) {
    final yesterdayKey = formatDateKey(today.subtract(const Duration(days: 1)));
    frozenDateKeys = [...frozenDateKeys, yesterdayKey];
    freezesAvailable -= 1;
  }

  // Bump once per cold start — Phase 4's "never during the first session
  // ever" interstitial rule reads this back as sessionCount > 1.
  final initialSettings = loadedSettings.copyWith(
    sessionCount: loadedSettings.sessionCount + 1,
    streakFreezesAvailable: freezesAvailable,
    frozenDateKeys: frozenDateKeys,
    freezeGrantMonthKey: () => freezeGrantMonthKey,
  );
  await settingsRepository.updateSettings(initialSettings);

  // No google-services.json / GoogleService-Info.plist configured yet in
  // this environment — Analytics simply stays disabled rather than
  // crashing startup. See FirebaseAnalyticsService.
  FirebaseAnalytics? analytics;
  try {
    await Firebase.initializeApp();
    analytics = FirebaseAnalytics.instance;
  } on Object {
    analytics = null;
  }

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
        initialAppSettingsProvider.overrideWithValue(initialSettings),
        firebaseAnalyticsInstanceProvider.overrideWithValue(analytics),
      ],
      child: const NonogramDailyApp(),
    ),
  );
}

class NonogramDailyApp extends ConsumerStatefulWidget {
  const NonogramDailyApp({super.key});

  @override
  ConsumerState<NonogramDailyApp> createState() => _NonogramDailyAppState();
}

class _NonogramDailyAppState extends ConsumerState<NonogramDailyApp>
    with WidgetsBindingObserver {
  DateTime? _sessionStart;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionStart = DateTime.now();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused) return;
    final start = _sessionStart;
    if (start == null) return;
    ref
        .read(analyticsServiceProvider)
        .logSessionLength(DateTime.now().difference(start));
    _sessionStart = null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedThemeId = ref.watch(
      appSettingsControllerProvider.select((s) => s.selectedThemeId),
    );
    final seed = AppColorTheme.fromId(selectedThemeId).seedColor;
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light(seed),
      darkTheme: AppTheme.dark(seed),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ConsentGate(child: _HomeRouter()),
    );
  }
}

/// Shows the tutorial before the player's first-ever puzzle, then
/// `DailyScreen` from then on. Reactive rather than a one-time
/// `Navigator` push: once `TutorialScreen` marks itself seen, this
/// rebuilds and swaps itself out on its own.
class _HomeRouter extends ConsumerWidget {
  const _HomeRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSeenTutorial = ref.watch(
      appSettingsControllerProvider.select((s) => s.hasSeenTutorial),
    );
    return hasSeenTutorial ? const DailyScreen() : const TutorialScreen();
  }
}
