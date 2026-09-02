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

    test(
      'allTagIds excludes karisik but includes every Z Kuşağı sub-branch',
      () {
        expect(InterestProfile.allTagIds, isNot(contains('karisik')));
        expect(InterestProfile.allTagIds, contains('z_kusagi'));
        expect(
          InterestProfile.allTagIds.where((id) => id.startsWith('z_kusagi_')),
          hasLength(5),
        );
      },
    );

    test('allTagIds has no duplicates', () {
      expect(
        InterestProfile.allTagIds.toSet().length,
        InterestProfile.allTagIds.length,
      );
    });
  });
}
