# AppLovin MAX (locked ad mediation SDK — see CLAUDE.MD) and any mediated
# adapter it loads reflectively.
-keep public class com.applovin.** { *; }
-keep public class com.applovin.sdk.** { *; }
-keep public class com.applovin.impl.** { *; }
-dontwarn com.applovin.**

# AppLovin bundles the IAB Open Measurement SDK (com.iab.omid.*), which
# references an optional Amazon PrivacyPass attestation API that isn't on
# the classpath unless that specific dependency is added. R8 fails the
# build over these missing classes even though the referencing code path
# never runs without it — surfaced by a real release build failure here,
# not a hypothetical.
-dontwarn com.amazon.privacypass.**
-dontwarn com.iab.omid.**

# Google Mobile Ads SDK — used only for its UMP consent APIs (see CLAUDE.MD's
# Phase 4 notes), not as the ad network, but still needs to survive R8.
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Firebase Analytics.
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
