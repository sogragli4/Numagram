# Windows fallback for environments without `make` installed.
# Usage: .\make.ps1 <target>   e.g. .\make.ps1 gen
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("get", "gen", "gen-watch", "test-setup", "test", "analyze", "format", "clean", "assets", "icons", "splash", "build-android-release", "size-report")]
    [string]$Target
)

switch ($Target) {
    "get"       { flutter pub get }
    "gen"       { flutter pub get; dart run build_runner build --delete-conflicting-outputs }
    "gen-watch" { flutter pub get; dart run build_runner watch --delete-conflicting-outputs }
    "test-setup" { dart run tool/test_setup.dart }
    "test"      { flutter test }
    "analyze"   { flutter analyze --fatal-infos --fatal-warnings }
    "format"    { dart format lib test }
    "clean"     { flutter clean }
    "assets"    { dart run tool/generate_icon_assets.dart }
    "icons"     { dart run tool/generate_icon_assets.dart; dart run flutter_launcher_icons }
    "splash"    { dart run tool/generate_icon_assets.dart; dart run flutter_native_splash:create }
    "build-android-release" { flutter build apk --release --obfuscate --split-debug-info=build/symbols }
    # --analyze-size can't handle a multi-ABI APK, so this pins one ABI —
    # arm64 covers virtually all real Android devices sold since ~2019.
    "size-report" { flutter build apk --release --analyze-size --target-platform android-arm64 }
}
