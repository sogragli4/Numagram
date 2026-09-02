import 'dart:typed_data';

import 'package:meta/meta.dart';

/// An immutable `width` × `height` boolean grid, bit-packed rather than
/// stored as `List<List<bool>>`.
///
/// Row-major cell order: cell `(row, col)` lives at bit index
/// `row * width + col`.
@immutable
class PuzzleGrid {
  const PuzzleGrid._(this.width, this.height, this._bits);

  factory PuzzleGrid.empty(int width, int height) {
    _validateDimensions(width, height);
    return PuzzleGrid._(
      width,
      height,
      Uint32List(_wordCountFor(width, height)),
    );
  }

  /// Builds a grid from a row-major flat list of booleans.
  factory PuzzleGrid.fromBools(int width, int height, List<bool> cells) {
    _validateDimensions(width, height);
    if (cells.length != width * height) {
      throw ArgumentError(
        'Expected ${width * height} cells for a $width x $height grid, '
        'got ${cells.length}.',
      );
    }
    final bits = Uint32List(_wordCountFor(width, height));
    for (var i = 0; i < cells.length; i++) {
      if (cells[i]) {
        bits[i >> 5] |= 1 << (i & 31);
      }
    }
    return PuzzleGrid._(width, height, bits);
  }

  final int width;
  final int height;
  final Uint32List _bits;

  static void _validateDimensions(int width, int height) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError(
        'Grid dimensions must be positive, got $width x $height.',
      );
    }
  }

  static int _wordCountFor(int width, int height) =>
      ((width * height) + 31) >> 5;

  bool cellAt(int row, int col) {
    RangeError.checkValueInInterval(row, 0, height - 1, 'row');
    RangeError.checkValueInInterval(col, 0, width - 1, 'col');
    final index = row * width + col;
    return (_bits[index >> 5] & (1 << (index & 31))) != 0;
  }

  /// Row `row` as a flat list of booleans, left to right.
  List<bool> rowCells(int row) =>
      List.generate(width, (col) => cellAt(row, col));

  /// Column `col` as a flat list of booleans, top to bottom.
  List<bool> columnCells(int col) =>
      List.generate(height, (row) => cellAt(row, col));

  int get filledCount {
    var count = 0;
    for (final word in _bits) {
      count += _popCount(word);
    }
    return count;
  }

  static int _popCount(int word) {
    var count = 0;
    var w = word;
    while (w != 0) {
      w &= w - 1;
      count++;
    }
    return count;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PuzzleGrid) return false;
    if (width != other.width || height != other.height) return false;
    for (var i = 0; i < _bits.length; i++) {
      if (_bits[i] != other._bits[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(width, height, Object.hashAll(_bits));

  @override
  String toString() {
    final buffer = StringBuffer('PuzzleGrid($width x $height)\n');
    for (var r = 0; r < height; r++) {
      for (var c = 0; c < width; c++) {
        buffer.write(cellAt(r, c) ? '#' : '.');
      }
      buffer.write('\n');
    }
    return buffer.toString();
  }
}
