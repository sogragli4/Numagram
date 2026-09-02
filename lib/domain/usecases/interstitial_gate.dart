import 'package:nonogram_daily/core/constants.dart';

/// Decides whether a free-play interstitial is allowed to show right now,
/// per the Phase 4 spec:
/// - only in free play, after a completed puzzle
/// - at least [AdLimits.interstitialCooldown] since the last one
/// - never more than 1 per [AdLimits.interstitialMinCompletions] completions
/// - never the daily puzzle (callers simply never call this for daily —
///   see `BoardController`)
/// - never in the first session ever, and never before the player's first
///   completed puzzle ever
///
/// Pure and synchronous, with an injectable clock so frequency-capping
/// logic is deterministically testable. One instance lives for the app's
/// process lifetime (frequency state doesn't need to survive a restart —
/// the "first session" / "first completion" rules are what's persisted,
/// via `AppSettings`).
class InterstitialGate {
  InterstitialGate({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  DateTime? _lastShownAt;
  int _completionsSinceLastInterstitial = 0;

  bool isEligible({
    required bool isFreePlay,
    required int sessionCount,
    required bool hasCompletedFirstPuzzleEver,
  }) {
    if (!FeatureFlags.interstitialAdEnabled) return false;
    if (!isFreePlay) return false;
    if (sessionCount <= 1) return false;
    if (!hasCompletedFirstPuzzleEver) return false;
    if (_completionsSinceLastInterstitial <
        AdLimits.interstitialMinCompletions) {
      return false;
    }
    final lastShown = _lastShownAt;
    if (lastShown != null &&
        _now().difference(lastShown) < AdLimits.interstitialCooldown) {
      return false;
    }
    return true;
  }

  /// Call once per free-play completion, regardless of [isEligible] —
  /// it's what makes the counter advance toward the next eligible show.
  void recordFreePlayCompletion() {
    _completionsSinceLastInterstitial++;
  }

  /// Call after the interstitial actually displayed.
  void recordShown() {
    _lastShownAt = _now();
    _completionsSinceLastInterstitial = 0;
  }
}
