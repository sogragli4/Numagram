import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:nonogram_daily/services/analytics/analytics_service.dart';

/// [AnalyticsService] backed by Firebase Analytics.
///
/// The constructor argument is `null` when `Firebase.initializeApp()`
/// wasn't run (no `google-services.json` / `GoogleService-Info.plist`
/// configured for this build) — every method then silently no-ops
/// rather than throwing, same "disabled without config" pattern as the
/// ad services.
class FirebaseAnalyticsService implements AnalyticsService {
  const FirebaseAnalyticsService(this._analytics);

  final FirebaseAnalytics? _analytics;

  Future<void> _log(String name, [Map<String, Object>? parameters]) async {
    final analytics = _analytics;
    if (analytics == null) return;
    await analytics.logEvent(name: name, parameters: parameters);
  }

  @override
  Future<void> logPuzzleStarted({
    required String source,
    required int width,
    required int height,
  }) => _log('puzzle_started', {
    'source': source,
    'width': width,
    'height': height,
  });

  @override
  Future<void> logPuzzleCompleted({
    required String source,
    required int elapsedSeconds,
    required bool perfect,
  }) => _log('puzzle_completed', {
    'source': source,
    'elapsed_seconds': elapsedSeconds,
    'perfect': perfect,
  });

  @override
  Future<void> logStreakExtended({required int streak}) =>
      _log('streak_extended', {'streak': streak});

  @override
  Future<void> logStreakBroken({required int previousStreak}) =>
      _log('streak_broken', {'previous_streak': previousStreak});

  @override
  Future<void> logRewardedShown({required String placement}) =>
      _log('rewarded_shown', {'placement': placement});

  @override
  Future<void> logRewardedCompleted({required String placement}) =>
      _log('rewarded_completed', {'placement': placement});

  @override
  Future<void> logInterstitialShown() => _log('interstitial_shown');

  @override
  Future<void> logHintUsed() => _log('hint_used');

  @override
  Future<void> logSessionLength(Duration length) =>
      _log('session_length', {'seconds': length.inSeconds});
}
