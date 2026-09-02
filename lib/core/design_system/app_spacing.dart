/// The app's 8px spacing scale — every gap, padding, and margin in new
/// UI code should come from here rather than a literal number, so
/// spacing stays visually consistent across screens.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double smMd = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double xxxl = 48;

  /// The standard horizontal screen padding, used on every top-level
  /// screen body so content margins line up app-wide.
  static const double screenHorizontal = md;

  /// The minimum comfortable touch target size (accessibility rule:
  /// "interactive elements should have comfortable touch targets") —
  /// matches `BoardLayout.minTouchTargetSize`, Nonogram's own existing
  /// 44pt standard, so the whole app agrees on one number rather than
  /// each screen picking its own.
  static const double minTouchTarget = 44;
}
