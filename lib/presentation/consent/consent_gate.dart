import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nonogram_daily/core/injection.dart';
import 'package:nonogram_daily/presentation/consent/att_explainer_screen.dart';

/// Runs the Phase 4 compliance sequence once, after the first frame:
/// Google UMP consent, then (only if ads may be requested) ad SDK
/// init, then — iOS only — the ATT explainer and system prompt.
///
/// Wraps the app's home content rather than blocking it: gameplay
/// doesn't depend on ads being ready, so there's no reason to hold the
/// UI behind a splash screen for this.
class ConsentGate extends ConsumerStatefulWidget {
  const ConsentGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ConsentGate> createState() => _ConsentGateState();
}

class _ConsentGateState extends ConsumerState<ConsentGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  /// Never lets a consent/ad-SDK/ATT failure — missing plugin, no
  /// network, misconfigured project — propagate as an unhandled error.
  /// Worst case: ads/analytics simply stay off for this session, same
  /// "disabled without config" fallback used everywhere else in Phase 4.
  Future<void> _run() async {
    try {
      final canRequestAds = await ref
          .read(consentServiceProvider)
          .resolveConsent();
      if (canRequestAds) {
        await ref.read(adServiceProvider).initialize();
      }
      if (!mounted) return;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _handleAppTrackingTransparency();
      }
    } on Object {
      // Intentionally swallowed — see doc comment above.
    }
  }

  Future<void> _handleAppTrackingTransparency() async {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status != TrackingStatus.notDetermined) return;
    if (!mounted) return;

    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AttExplainerScreen()));
    await AppTrackingTransparency.requestTrackingAuthorization();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
