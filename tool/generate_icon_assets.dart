// Generates placeholder app icon / adaptive-icon foreground / splash logo
// PNGs from pure Dart (no design tool available in this environment) —
// a bold 3x3 "filled corners + center" block mark, echoing a partially
// solved nonogram grid. Intentionally simple/geometric so it reads
// clearly at small sizes; swap these source files for real artwork
// whenever the founder has some, then re-run `make icons` / `make splash`.
//
// Run: dart run tool/generate_icon_assets.dart
import 'dart:io';

import 'package:image/image.dart' as img;

final _seedColor = img.ColorRgba8(0x3D, 0x5A, 0xFE, 255);
final _white = img.ColorRgba8(0xFF, 0xFF, 0xFF, 255);
final _transparent = img.ColorRgba8(0, 0, 0, 0);
const _canvasSize = 1024;

/// 3x3 "X" pattern — corners and centre filled, like a partially solved
/// nonogram line-up. Bold and symmetric enough to read at 24px.
const _pattern = [
  [true, false, true],
  [false, true, false],
  [true, false, true],
];

void _drawPattern(
  img.Image image, {
  required img.Color cellColor,
  required double contentFraction,
}) {
  final content = (_canvasSize * contentFraction).round();
  final origin = (_canvasSize - content) ~/ 2;
  const cells = 3;
  final gap = (content * 0.08).round();
  final cellSize = (content - gap * (cells - 1)) ~/ cells;

  for (var row = 0; row < cells; row++) {
    for (var col = 0; col < cells; col++) {
      if (!_pattern[row][col]) continue;
      final x1 = origin + col * (cellSize + gap);
      final y1 = origin + row * (cellSize + gap);
      img.fillRect(
        image,
        x1: x1,
        y1: y1,
        x2: x1 + cellSize,
        y2: y1 + cellSize,
        color: cellColor,
      );
    }
  }
}

img.Image _newCanvas() =>
    img.Image(width: _canvasSize, height: _canvasSize, numChannels: 4);

void _save(img.Image image, String path) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(image));
  // ignore: avoid_print
  print('Wrote $path');
}

void main() {
  // Main / legacy icon: opaque seed-blue background, white mark.
  final icon = _newCanvas();
  img.fill(icon, color: _seedColor);
  _drawPattern(icon, cellColor: _white, contentFraction: 0.6);
  _save(icon, 'assets/icon/app_icon.png');

  // Adaptive-icon foreground: transparent background, white mark, kept
  // inside adaptive icons' visible safe zone (roughly the centre 66%).
  final foreground = _newCanvas();
  img.fill(foreground, color: _transparent);
  _drawPattern(foreground, cellColor: _white, contentFraction: 0.42);
  _save(foreground, 'assets/icon/app_icon_foreground.png');

  // Splash logo: transparent background, seed-blue mark (splash
  // background is near-white/near-black, so the mark carries its own
  // colour to stay visible in both).
  final splash = _newCanvas();
  img.fill(splash, color: _transparent);
  _drawPattern(splash, cellColor: _seedColor, contentFraction: 0.5);
  _save(splash, 'assets/icon/splash_logo.png');
}
