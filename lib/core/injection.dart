import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:nonogram_daily/data/datasources/isar_local_data_source.dart';
import 'package:nonogram_daily/data/datasources/puzzle_generator_data_source.dart';
import 'package:nonogram_daily/data/repositories/puzzle_repository_impl.dart';
import 'package:nonogram_daily/data/repositories/settings_repository_impl.dart';
import 'package:nonogram_daily/data/repositories/streak_repository_impl.dart';
import 'package:nonogram_daily/domain/repositories/puzzle_repository.dart';
import 'package:nonogram_daily/domain/repositories/settings_repository.dart';
import 'package:nonogram_daily/domain/repositories/streak_repository.dart';
import 'package:nonogram_daily/domain/usecases/generate_daily_puzzle.dart';
import 'package:nonogram_daily/domain/usecases/interstitial_gate.dart';
import 'package:nonogram_daily/domain/usecases/update_streak.dart';
import 'package:nonogram_daily/services/ads/ad_service.dart';
import 'package:nonogram_daily/services/ads/max_ad_service.dart';
import 'package:nonogram_daily/services/analytics/analytics_service.dart';
import 'package:nonogram_daily/services/analytics/firebase_analytics_service.dart';
import 'package:nonogram_daily/services/consent/consent_service.dart';
import 'package:nonogram_daily/services/consent/ump_consent_service.dart';
import 'package:nonogram_daily/services/notifications/local_notification_service.dart';
import 'package:nonogram_daily/services/notifications/notification_service.dart';
import 'package:nonogram_daily/services/sound/audioplayers_sound_service.dart';
import 'package:nonogram_daily/services/sound/sound_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'injection.g.dart';

/// Overridden in `main()` with the already-opened Isar instance — opening
/// it is async and happens once, before `runApp`, so every other provider
/// here can stay synchronous.
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError(
    'isarProvider must be overridden with an opened Isar instance in main()',
  );
});

@riverpod
IsarLocalDataSource isarLocalDataSource(Ref ref) =>
    IsarLocalDataSource(ref.watch(isarProvider));

@riverpod
PuzzleGeneratorDataSource puzzleGeneratorDataSource(Ref ref) =>
    const PuzzleGeneratorDataSource();

@riverpod
PuzzleRepository puzzleRepository(Ref ref) =>
    PuzzleRepositoryImpl(ref.watch(puzzleGeneratorDataSourceProvider));

@riverpod
StreakRepository streakRepository(Ref ref) =>
    StreakRepositoryImpl(ref.watch(isarLocalDataSourceProvider));

@riverpod
SettingsRepository settingsRepository(Ref ref) =>
    SettingsRepositoryImpl(ref.watch(isarLocalDataSourceProvider));

@riverpod
GenerateDailyPuzzle generateDailyPuzzle(Ref ref) =>
    GenerateDailyPuzzle(ref.watch(puzzleRepositoryProvider));

@riverpod
UpdateStreak updateStreak(Ref ref) =>
    UpdateStreak(ref.watch(streakRepositoryProvider));

@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) => LocalNotificationService();

/// Overridden in `main()` with the result of `Firebase.initializeApp()` —
/// `null` if it failed or wasn't configured (no `google-services.json` /
/// `GoogleService-Info.plist`), in which case [analyticsServiceProvider]
/// silently no-ops rather than throwing.
final firebaseAnalyticsInstanceProvider = Provider<FirebaseAnalytics?>(
  (ref) => null,
);

@Riverpod(keepAlive: true)
AnalyticsService analyticsService(Ref ref) =>
    FirebaseAnalyticsService(ref.watch(firebaseAnalyticsInstanceProvider));

@Riverpod(keepAlive: true)
ConsentService consentService(Ref ref) => const UmpConsentService();

@Riverpod(keepAlive: true)
AdService adService(Ref ref) => MaxAdService(MaxAdConfig.fromDartDefines());

/// One per app process — frequency-capping state deliberately doesn't
/// survive a restart (see `InterstitialGate`).
@Riverpod(keepAlive: true)
InterstitialGate interstitialGate(Ref ref) => InterstitialGate();

@Riverpod(keepAlive: true)
SoundService soundService(Ref ref) => AudioPlayersSoundService();
