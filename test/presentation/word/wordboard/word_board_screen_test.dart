import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/core/injection.dart';
import 'package:nonogram_daily/core/l10n_gen/app_localizations.dart';
import 'package:nonogram_daily/core/theme.dart';
import 'package:nonogram_daily/domain/entities/word/word_progress.dart';
import 'package:nonogram_daily/domain/repositories/word_progress_repository.dart';
import 'package:nonogram_daily/presentation/word/word_progress_controller.dart';
import 'package:nonogram_daily/presentation/word/wordboard/word_board_controller.dart';
import 'package:nonogram_daily/presentation/word/wordboard/word_board_screen.dart';

/// No real Isar instance is wired into this narrow widget test's
/// container (unlike `main()`, which always provides one) — this stands
/// in so winning the demo crossword can record completion without
/// needing real persistence, the same "fake the plugin/service this test
/// doesn't care about" pattern `widget_test.dart`'s
/// `_FakeConsentService`/`_FakeAdService` already use.
class _FakeWordProgressRepository implements WordProgressRepository {
  @override
  Future<WordProgress> getProgress() async => WordProgress.defaults;

  @override
  Future<void> updateProgress(WordProgress progress) async {}
}

void main() {
  testWidgets('typing every entry through the on-screen keyboard, including a '
      'wrong letter that must not stick, solves the demo crossword', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        // Winning the demo crossword now also records completion via
        // `WordProgressController` — this test drives a real win, so it
        // needs the same override `main()` provides in the real app.
        initialWordProgressProvider.overrideWithValue(WordProgress.defaults),
        wordProgressRepositoryProvider.overrideWithValue(
          _FakeWordProgressRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    // `WordBoardController` is `@riverpod` (autoDispose) — keep it
    // alive across the test the same way `tutorial_screen_test.dart`
    // keeps `AppSettingsController` alive when pumping a screen
    // directly, outside its normal parent context.
    container.listen(wordBoardControllerProvider, (_, _) {});

    // flutter_test's default surface is wider than a real phone — the
    // on-screen keyboard's real overflow bug (see `_CrosswordKeyboard`'s
    // doc comment) rendered clean at the default size and only showed up
    // on an actual device. Pinning a narrow, real-phone-ish width here
    // means a regression of that exact bug fails this test too, instead
    // of needing another manual device check to catch it.
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          // `AppColors` is only registered as a `ThemeExtension` via
          // `AppTheme.light`/`dark` (see `main.dart`) — a bare
          // `MaterialApp` with no `theme:` has no extension registered,
          // and `context.appColors` null-checks on that.
          theme: AppTheme.light(const Color(0xFF3D5AFE)),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WordBoardScreen(),
        ),
      ),
    );
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    Future<void> type(String letter) async {
      await tester.tap(find.text(letter));
      await tester.pump();
    }

    Future<void> selectClueByText(String clueText) async {
      await tester.tap(find.byIcon(Icons.list_alt));
      await tester.pumpAndSettle();
      await tester.tap(find.text(clueText));
      await tester.pumpAndSettle();
    }

    // 1-Across starts active by default: KİTAP, first cell (0,0) = 'K'.
    // A wrong letter first — must not be written into the grid, but
    // must count as a mistake.
    await type('X');
    var state = container.read(wordBoardControllerProvider);
    expect(state.session.typedLetters[(0, 0)], isNull);
    expect(state.mistakeCount, 1);

    for (final letter in 'KİTAP'.split('')) {
      await type(letter);
    }
    state = container.read(wordBoardControllerProvider);
    expect(
      state.session.isEntrySolved(
        state.session.puzzle.entries.firstWhere((e) => e.id == 'across-1'),
      ),
      isTrue,
    );

    // KİTAP being solved doesn't auto-advance to a *different* entry —
    // only a same-entry advance is automatic — so the remaining down
    // entries are reached via the clue sheet.
    await selectClueByText('Uçabilen hayvan');
    for (final letter in 'UŞ'.split('')) {
      await type(letter);
    }

    await selectClueByText('Yumurtlayan çiftlik hayvanı');
    for (final letter in 'AVUK'.split('')) {
      await type(letter);
    }

    await selectClueByText('Yeşil alan, oyun bahçesi');
    for (final letter in 'ARK'.split('')) {
      await type(letter);
    }

    await tester.pump();
    expect(container.read(wordBoardControllerProvider).session.won, isTrue);
    expect(find.text(l10n.puzzleCompletedTitle), findsOneWidget);
  });
}
