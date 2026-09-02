/// Turkish-locale-aware uppercasing. Dart's built-in `String.toUpperCase()`
/// is not locale-aware: it turns `'i'` into dotless `'I'`, which is wrong
/// for Turkish — the correct uppercase of `'i'` is dotted `'İ'`, and
/// dotless `'I'` is instead the uppercase of `'ı'`. Used wherever
/// player-typed or stored Turkish text needs case-insensitive comparison
/// (the word puzzle game mode's letter-by-letter answer checking).
String toTurkishUpperCase(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    switch (char) {
      case 'i':
        buffer.write('İ');
      case 'ı':
        buffer.write('I');
      default:
        buffer.write(char.toUpperCase());
    }
  }
  return buffer.toString();
}
