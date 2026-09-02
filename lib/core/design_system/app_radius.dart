import 'package:flutter/widgets.dart';

/// The app's border-radius scale — every rounded corner in new UI code
/// should come from here rather than a literal number, so corner
/// rounding stays consistent across cards, buttons, and keys. Values
/// deliberately stay modest (max 24) — a "premium/minimal" surface reads
/// as considered, not as a rounded-corner showcase.
abstract final class AppRadius {
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 18;
  static const double xxl = 24;

  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlRadius = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius xxlRadius = BorderRadius.all(Radius.circular(xxl));
}
