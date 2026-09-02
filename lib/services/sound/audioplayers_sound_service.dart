import 'package:audioplayers/audioplayers.dart';
import 'package:nonogram_daily/services/sound/sound_service.dart';

const _assetPaths = {
  SoundEffect.fill: 'sounds/fill.wav',
  SoundEffect.mark: 'sounds/mark.wav',
  SoundEffect.mistake: 'sounds/mistake.wav',
  SoundEffect.win: 'sounds/win.wav',
};

/// [SoundService] backed by `audioplayers`. Each effect gets its own
/// [AudioPool] — audioplayers' purpose-built pre-loaded, low-latency
/// player pool for "extremely quick firing, repetitive ... sounds",
/// exactly the fill/mark case during a fast paint-drag stroke — created
/// lazily on first use rather than all four at once at startup.
///
/// Never lets a playback failure (no audio output device, a missing
/// asset, a plugin issue on a platform that doesn't register it) escape
/// as an unhandled error: worst case is silence, the same "disabled
/// without config" fallback every other service in this app uses.
class AudioPlayersSoundService implements SoundService {
  final Map<SoundEffect, Future<AudioPool>> _pools = {};

  Future<AudioPool> _poolFor(SoundEffect effect) => _pools.putIfAbsent(
    effect,
    () => AudioPool.createFromAsset(
      path: _assetPaths[effect]!,
      maxPlayers: 4,
      playerMode: PlayerMode.lowLatency,
    ),
  );

  @override
  Future<void> play(SoundEffect effect) async {
    try {
      final pool = await _poolFor(effect);
      await pool.start();
    } on Object {
      // Intentionally swallowed — see class doc comment.
    }
  }
}
