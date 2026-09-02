import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:nonogram_daily/services/consent/consent_service.dart';

/// [ConsentService] backed by Google's User Messaging Platform SDK
/// (bundled in `google_mobile_ads`). Network-agnostic — this governs
/// consent for the locked ad network (AppLovin MAX) just as well as it
/// would for AdMob; UMP doesn't require AdMob to be the ad source.
class UmpConsentService implements ConsentService {
  const UmpConsentService();

  @override
  Future<bool> resolveConsent() {
    final completer = Completer<bool>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          await ConsentForm.loadAndShowConsentFormIfRequired((_) async {
            final canRequestAds = await ConsentInformation.instance
                .canRequestAds();
            if (!completer.isCompleted) completer.complete(canRequestAds);
          });
        } else {
          final canRequestAds = await ConsentInformation.instance
              .canRequestAds();
          if (!completer.isCompleted) completer.complete(canRequestAds);
        }
      },
      (_) {
        // Consent info update failed (e.g. no network) — fail safe by not
        // allowing ad requests rather than guessing.
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    return completer.future;
  }
}
