import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/entities/word/interest_profile.dart';

void main() {
  group('InterestProfile', () {
    test('empty constant has no selected tags', () {
      expect(InterestProfile.empty.isEmpty, isTrue);
    });

    test('isEmpty is false once a tag is selected', () {
      const profile = InterestProfile(selectedTagIds: {'tarih_osmanli'});
      expect(profile.isEmpty, isFalse);
    });

    test('equality ignores selection order', () {
      const a = InterestProfile(selectedTagIds: {'a', 'b'});
      const b = InterestProfile(selectedTagIds: {'b', 'a'});
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different tag sets are unequal', () {
      const a = InterestProfile(selectedTagIds: {'a'});
      const b = InterestProfile(selectedTagIds: {'a', 'b'});
      expect(a, isNot(b));
    });
  });
}
