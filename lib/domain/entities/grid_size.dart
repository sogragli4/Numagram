import 'package:meta/meta.dart';

/// A puzzle's dimensions, as a small value type rather than a bare
/// `(int, int)` pair so call sites read `size.width` / `size.height`.
@immutable
class GridSize {
  const GridSize(this.width, this.height);

  final int width;
  final int height;

  int get cellCount => width * height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GridSize && width == other.width && height == other.height);

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => '$width x $height';
}
