import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/core/l10n_gen/app_localizations.dart';
import 'package:nonogram_daily/presentation/word/wordboard/word_board_screen.dart';

void main() {
  testWidgets(
    'typing every answer, including a wrong letter that must not stick, '
    'solves the demo section',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: WordBoardScreen(),
          ),
        ),
      );
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final hiddenField = find.byType(TextField);

      // Focus the very first box — every later box is auto-focused by the
      // controller's own advance-on-correct-letter logic, so this is the
      // only tap this test needs.
      await tester.tap(find.byKey(const ValueKey('letterBox_demo-1_0')));
      await tester.pump();

      // A wrong letter first: must not be written into the box.
      await tester.enterText(hiddenField, 'x');
      await tester.pump();
      expect(find.text('X'), findsNothing);

      // FATİH, ANKARA, İSTANBUL, LİRA, in order — each clue's last
      // correct letter auto-advances focus to the next clue's first box.
      for (final letter in 'fatihankaraistanbullira'.split('')) {
        await tester.enterText(hiddenField, letter);
        await tester.pump();
      }

      await tester.pump();
      expect(find.text(l10n.puzzleCompletedTitle), findsOneWidget);
    },
  );
}
