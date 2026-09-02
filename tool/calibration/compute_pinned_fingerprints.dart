// ignore_for_file: avoid_print
import 'package:nonogram_daily/domain/engine/puzzle_generator.dart';
import 'package:nonogram_daily/domain/engine/stable_hash.dart';

int fingerprint(int width, int height, bool Function(int row, int col) cellAt) {
  final buffer = StringBuffer();
  for (var r = 0; r < height; r++) {
    for (var c = 0; c < width; c++) {
      buffer.write(cellAt(r, c) ? '1' : '0');
    }
  }
  return fnv1a64(buffer.toString());
}

void main() {
  const dates = [(2024, 1, 1), (2025, 6, 15), (2026, 9, 1), (2030, 12, 31)];
  for (final (y, m, d) in dates) {
    final seed = seedForDate(DateTime(y, m, d));
    final puzzle = generatePuzzle(seed: seed, width: 10, height: 10);
    final fp = fingerprint(10, 10, puzzle.solution.cellAt);
    final key =
        '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
    print("'$key': ($y, $m, $d, $fp),");
  }
}
