/// A seeded PRNG (SplitMix64), used instead of `dart:math`'s `Random(seed)`.
///
/// `Random(seed)`'s exact output sequence is not a documented, frozen
/// contract — an unrelated Dart SDK upgrade could change it and silently
/// regenerate every past daily puzzle differently. Owning the algorithm
/// here keeps puzzle generation reproducible forever, independent of the
/// SDK version the app happens to be built with.
class DeterministicRandom {
  DeterministicRandom(int seed) : _state = seed;

  int _state;

  int nextRaw() {
    _state += 0x9E3779B97F4A7C15;
    var z = _state;
    z = (z ^ (z >>> 30)) * 0xBF58476D1CE4E5B9;
    z = (z ^ (z >>> 27)) * 0x94D049BB133111EB;
    return z ^ (z >>> 31);
  }

  /// Uniform double in `[0, 1)`.
  double nextDouble() => (nextRaw() >>> 11) / (1 << 53);

  /// `true` with probability [probabilityTrue].
  bool nextBool(double probabilityTrue) => nextDouble() < probabilityTrue;

  /// Uniform int in `[0, max)`.
  int nextInt(int max) {
    if (max <= 0) throw ArgumentError.value(max, 'max', 'must be positive');
    return (nextRaw() >>> 1) % max;
  }
}
