.PHONY: gen gen-watch test test-setup analyze format clean get icons splash assets build-android-release size-report

get:
	flutter pub get

gen: get
	dart run build_runner build --delete-conflicting-outputs

gen-watch: get
	dart run build_runner watch --delete-conflicting-outputs

# One-time (and after `flutter pub upgrade` touches Isar): copies Isar's
# native library into the project root so `flutter test` can open a real
# Isar instance. Not needed to run the app itself, only its tests.
test-setup:
	dart run tool/test_setup.dart

test:
	flutter test

analyze:
	flutter analyze --fatal-infos --fatal-warnings

format:
	dart format lib test

clean:
	flutter clean

# Regenerates assets/icon/*.png from the programmatic placeholder mark.
# Re-run whenever real artwork replaces those source files.
assets:
	dart run tool/generate_icon_assets.dart

icons: assets
	dart run flutter_launcher_icons

splash: assets
	dart run flutter_native_splash:create

# Release build with obfuscation on (Phase 5 spec) — debug symbols are
# written out separately so stack traces from crash reports can still be
# de-obfuscated later.
build-android-release:
	flutter build apk --release --obfuscate --split-debug-info=build/symbols

# Human-readable breakdown of what's taking up space in the release APK.
# --analyze-size can't handle a multi-ABI APK, so this pins one ABI — arm64
# covers virtually all real Android devices sold since ~2019.
size-report:
	flutter build apk --release --analyze-size --target-platform android-arm64
