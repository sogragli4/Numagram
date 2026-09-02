/// Short gameplay SFX, per the Phase 2 spec's "haptics on fill, mark,
/// mistake, and win" — one sound per event.
enum SoundEffect { fill, mark, mistake, win }

/// Plays [SoundEffect]s, behind an interface so it can be faked in tests
/// and safely no-op if audio playback isn't available for any reason.
abstract class SoundService {
  Future<void> play(SoundEffect effect);
}
