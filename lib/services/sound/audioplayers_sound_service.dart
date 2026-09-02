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
/// `play()`'s own `try`/`catch` swallows any failure in its awaited call
/// chain (missing asset, playback error), so worst case is silence, the
/// same "disabled without config" fallback every other service in this
/// app uses. One known gap, not fully closed by that `try`/`catch`:
/// `AudioPlayer`'s constructor (inside [AudioPool.createFromAsset])
/// registers a *global event-channel listener* that can throw
/// `MissingPluginException` asynchronously, from a callback outside
/// `play()`'s own await chain — real only where the native plugin
/// genuinely isn't registered (a widget test; never a shipped app,
/// where the plugin is always present). See CLAUDE.MD's "Sound effects"
/// section for the incident that surfaced this.
class AudioPlayersSoundService implements SoundService {
  final Map<SoundEffect, Future<AudioPool>> _pools = {};

  Future<AudioPool> _poolFor(SoundEffect effect) {
    final existing = _pools[effect];
    if (existing != null) return existing;

    final future = AudioPool.createFromAsset(
      path: _assetPaths[effect]!,
      maxPlayers: 4,
      playerMode: PlayerMode.lowLatency,
    );
    _pools[effect] = future;

    // A failed init must not permanently mute this effect: an
    // already-completed-with-error Future replays that same error to
    // every future listener, so without this, one transient failure
    // (e.g. the audio subsystem not ready yet right after launch) would
    // silence this effect for the rest of the session. This listener
    // only clears the cache entry on error — `future` itself (returned
    // below, and awaited by `play()`) still carries its own error for
    // that caller's own `try`/`catch` to handle.
    future.then(
      (_) {},
      onError: (Object _, StackTrace __) {
        if (identical(_pools[effect], future)) _pools.remove(effect);
      },
    );

    return future;
  }

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
