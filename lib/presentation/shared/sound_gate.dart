import 'package:nonogram_daily/core/injection.dart';
import 'package:nonogram_daily/presentation/settings/settings_controller.dart';
import 'package:nonogram_daily/services/sound/sound_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// Plays [effect] through [SoundService], unless the player has sound
/// disabled in settings. Shared by every controller that needs to play a
/// gameplay sound effect (`BoardController`, `TutorialController`) so the
/// enabled-check and the provider lookups live in exactly one place.
Future<void> playSoundIfEnabled(Ref ref, SoundEffect effect) {
  if (!ref.read(appSettingsControllerProvider).soundEnabled) {
    return Future.value();
  }
  return ref.read(soundServiceProvider).play(effect);
}
