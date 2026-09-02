import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/core/turkish_text.dart';

void main() {
  group('toTurkishUpperCase', () {
    test('dotted İ for lowercase i, not dotless I', () {
      expect(toTurkishUpperCase('istanbul'), 'İSTANBUL');
    });

    test('dotless I for lowercase ı', () {
      expect(toTurkishUpperCase('kırıkkale'), 'KIRIKKALE');
    });

    test('handles a word with both i and ı', () {
      expect(toTurkishUpperCase('fatih'), 'FATİH');
      expect(toTurkishUpperCase('ısırgan'), 'ISIRGAN');
    });

    test('other Turkish letters uppercase normally', () {
      expect(toTurkishUpperCase('şeker'), 'ŞEKER');
      expect(toTurkishUpperCase('çorum'), 'ÇORUM');
      expect(toTurkishUpperCase('güneş'), 'GÜNEŞ');
      expect(toTurkishUpperCase('öykü'), 'ÖYKÜ');
    });

    test('already-uppercase input is unchanged', () {
      expect(toTurkishUpperCase('İSTANBUL'), 'İSTANBUL');
      expect(toTurkishUpperCase('KIRIKKALE'), 'KIRIKKALE');
    });

    test('non-Turkish ASCII letters behave as normal uppercase', () {
      expect(toTurkishUpperCase('abc123'), 'ABC123');
    });

    test('empty string stays empty', () {
      expect(toTurkishUpperCase(''), '');
    });
  });
}
