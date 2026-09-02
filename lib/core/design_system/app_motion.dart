import 'package:flutter/animation.dart';

/// Suggested addition to the design system: named animation durations and
/// curves, so "subtle and purposeful" motion (fade / scale / slide, no
/// bouncing or continuous effects) has one shared source instead of each
/// screen picking its own `Duration(milliseconds: ...)` literal.
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 300);

  static const curve = Curves.easeOut;
}
