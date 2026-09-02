import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nonogram_daily/presentation/word/home/word_home_screen.dart';
import 'package:nonogram_daily/presentation/word/onboarding/interest_survey_screen.dart';
import 'package:nonogram_daily/presentation/word/word_progress_controller.dart';

/// Shows the ilgi alanı anketi before the player's first-ever visit to
/// the word game's home screen, then `WordHomeScreen` from then on —
/// reactively, not a one-time `Navigator` push, the same pattern
/// `_HomeRouter` (`main.dart`) already uses for
/// `TutorialScreen`/`GamePickerScreen`. `GamePickerScreen` pushes this
/// instead of `WordHomeScreen` directly.
class WordEntryRouter extends ConsumerWidget {
  const WordEntryRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSeenSurvey = ref.watch(
      wordProgressControllerProvider.select((p) => p.hasSeenInterestSurvey),
    );
    return hasSeenSurvey
        ? const WordHomeScreen()
        : const InterestSurveyScreen();
  }
}
