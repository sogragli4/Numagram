import 'package:flutter/widgets.dart';

/// Which rewarded placement is being shown — the Phase 4 spec's three
/// rewarded slots, each with its own ad unit and its own frequency rule
/// (enforced by the caller, not this service).
enum RewardedPlacement { hint, extraHeart, archiveUnlock }

/// AppLovin MAX ad placements, behind an interface so it can be faked in
/// tests and left inert wherever ad unit IDs aren't configured (debug
/// builds, or simply before the founder has real MAX credentials).
abstract class AdService {
  /// Runs once, after `ConsentService.resolveConsent` succeeds. No ad
  /// SDK call happens before this — see the Phase 4 compliance note.
  Future<void> initialize();

  /// Loads and shows a rewarded ad for [placement]. Resolves to whether
  /// the player actually earned the reward (watched to completion) —
  /// `false` on load failure, dismiss-before-completion, or if ads
  /// aren't configured/enabled.
  Future<bool> showRewarded(RewardedPlacement placement);

  /// Shows a preloaded interstitial. Resolves to whether it actually
  /// displayed. Callers are responsible for all placement/frequency
  /// rules (see `InterstitialGate`) — this just attempts the show.
  Future<bool> showInterstitial();

  /// A banner for the calling screen. Renders as an empty box when
  /// banners are disabled, unconfigured, or not yet loaded — callers
  /// don't need to check availability themselves.
  Widget buildBanner();
}
