// Generates placeholder short SFX WAV files from pure Dart (no audio
// tool/asset available in this environment) — simple sine-tone blips,
// distinct enough by pitch/shape to tell fill/mark/mistake/win apart.
// Swap these source files for real sound design whenever the founder has
// some; nothing else needs to change, `SoundService` just plays whatever
// is at these paths.
//
// Run: dart run tool/generate_sound_assets.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const _sampleRate = 44100;

/// One tone: a sine wave at [frequencyHz] for [durationMs], scaled by
/// [amplitude] (0-1) and shaped by a short linear attack/decay envelope
/// so it doesn't click at the start/end.
Float64List _tone({
  required double frequencyHz,
  required int durationMs,
  double amplitude = 0.5,
  int attackMs = 4,
  int? decayMs,
}) {
  final sampleCount = (_sampleRate * durationMs / 1000).round();
  final attackSamples = (_sampleRate * attackMs / 1000).round();
  final decaySamples = (_sampleRate * (decayMs ?? durationMs) / 1000).round();
  final samples = Float64List(sampleCount);

  for (var i = 0; i < sampleCount; i++) {
    final t = i / _sampleRate;
    var envelope = 1.0;
    if (i < attackSamples) {
      envelope = i / attackSamples;
    } else if (i > sampleCount - decaySamples) {
      envelope = (sampleCount - i) / decaySamples;
    }
    samples[i] = amplitude * envelope * math.sin(2 * math.pi * frequencyHz * t);
  }
  return samples;
}

Float64List _concat(List<Float64List> parts) {
  final total = parts.fold<int>(0, (sum, p) => sum + p.length);
  final out = Float64List(total);
  var offset = 0;
  for (final part in parts) {
    out.setAll(offset, part);
    offset += part.length;
  }
  return out;
}

void _writeWav(String path, Float64List samples) {
  const bitsPerSample = 16;
  const numChannels = 1;
  final byteRate = _sampleRate * numChannels * bitsPerSample ~/ 8;
  final blockAlign = numChannels * bitsPerSample ~/ 8;
  final dataSize = samples.length * blockAlign;

  final bytes = ByteData(44 + dataSize);
  var o = 0;
  void writeString(String s) {
    for (final c in s.codeUnits) {
      bytes.setUint8(o, c);
      o++;
    }
  }

  writeString('RIFF');
  bytes.setUint32(o, 36 + dataSize, Endian.little);
  o += 4;
  writeString('WAVE');
  writeString('fmt ');
  bytes.setUint32(o, 16, Endian.little);
  o += 4;
  bytes.setUint16(o, 1, Endian.little); // PCM
  o += 2;
  bytes.setUint16(o, numChannels, Endian.little);
  o += 2;
  bytes.setUint32(o, _sampleRate, Endian.little);
  o += 4;
  bytes.setUint32(o, byteRate, Endian.little);
  o += 4;
  bytes.setUint16(o, blockAlign, Endian.little);
  o += 2;
  bytes.setUint16(o, bitsPerSample, Endian.little);
  o += 2;
  writeString('data');
  bytes.setUint32(o, dataSize, Endian.little);
  o += 4;

  for (final sample in samples) {
    final clamped = sample.clamp(-1.0, 1.0);
    final intSample = (clamped * 32767).round();
    bytes.setInt16(o, intSample, Endian.little);
    o += 2;
  }

  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes.buffer.asUint8List());
  // ignore: avoid_print
  print('Wrote $path');
}

void main() {
  // Fill: a short, bright, satisfying blip.
  _writeWav(
    'assets/sounds/fill.wav',
    _tone(frequencyHz: 880, durationMs: 70, amplitude: 0.45),
  );

  // Mark: shorter and lower — a soft "click" distinct from fill.
  _writeWav(
    'assets/sounds/mark.wav',
    _tone(frequencyHz: 587, durationMs: 45, amplitude: 0.35, attackMs: 2),
  );

  // Mistake: low, longer, deliberately less pleasant.
  _writeWav(
    'assets/sounds/mistake.wav',
    _concat([
      _tone(frequencyHz: 220, durationMs: 90, amplitude: 0.5, attackMs: 2),
      _tone(frequencyHz: 196, durationMs: 110, amplitude: 0.5, attackMs: 2),
    ]),
  );

  // Win: a short rising major arpeggio (C5, E5, G5, C6).
  _writeWav(
    'assets/sounds/win.wav',
    _concat([
      _tone(frequencyHz: 523.25, durationMs: 110, amplitude: 0.45),
      _tone(frequencyHz: 659.25, durationMs: 110, amplitude: 0.45),
      _tone(frequencyHz: 783.99, durationMs: 110, amplitude: 0.45),
      _tone(frequencyHz: 1046.50, durationMs: 220, amplitude: 0.45),
    ]),
  );
}
