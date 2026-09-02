import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nonogram_daily/core/design_system/app_colors.dart';
import 'package:nonogram_daily/core/design_system/app_spacing.dart';
import 'package:nonogram_daily/core/design_system/app_typography.dart';
import 'package:nonogram_daily/core/l10n_gen/app_localizations.dart';
import 'package:nonogram_daily/domain/entities/word/interest_profile.dart';
import 'package:nonogram_daily/presentation/shared/app_button.dart';
import 'package:nonogram_daily/presentation/word/word_progress_controller.dart';

/// The multi-select ilgi alanı anketi shown once, before the player's
/// first word-puzzle track, right after the shared tutorial — same
/// `hasSeenX`-flag pattern as `TutorialScreen`'s `hasSeenTutorial`, here
/// `WordProgress.hasSeenInterestSurvey`. Shown by `WordEntryRouter`
/// reactively, the same way `_HomeRouter` swaps `TutorialScreen` out for
/// `GamePickerScreen`.
///
/// Continuing with zero tags selected is allowed — there's no separate
/// "skip" control, since an empty selection already behaves exactly like
/// a skip (the survey only re-orders/prioritizes content — see
/// `InterestProfile`'s doc comment — it never blocks anything).
class InterestSurveyScreen extends ConsumerStatefulWidget {
  const InterestSurveyScreen({super.key});

  @override
  ConsumerState<InterestSurveyScreen> createState() =>
      _InterestSurveyScreenState();
}

class _InterestSurveyScreenState extends ConsumerState<InterestSurveyScreen> {
  late final Set<String> _selected = Set.of(
    ref.read(wordProgressControllerProvider).interestTagIds,
  );

  String _labelFor(AppLocalizations l10n, String tagId) => switch (tagId) {
    'tarih' => l10n.wordSurveyTagTarih,
    'genel_kultur' => l10n.wordSurveyTagGenelKultur,
    'hukuk' => l10n.wordSurveyTagHukuk,
    'gundem' => l10n.wordSurveyTagGundem,
    'z_kusagi' => l10n.wordSurveyTagZKusagi,
    'z_kusagi_internet_kulturu' => l10n.wordSurveyTagInternetKulturu,
    'z_kusagi_dizi_sinema' => l10n.wordSurveyTagDiziSinema,
    'z_kusagi_muzik_trendler' => l10n.wordSurveyTagMuzikTrendler,
    'z_kusagi_oyun_kulturu' => l10n.wordSurveyTagOyunKulturu,
    'z_kusagi_sosyal_medya_gundemi' => l10n.wordSurveyTagSosyalMedyaGundemi,
    _ => tagId,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appColors = context.appColors;

    return Scaffold(
      backgroundColor: appColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.wordSurveyTitle,
                style: AppTypography.headlineMedium.copyWith(
                  color: appColors.navy,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.wordSurveyBody,
                style: AppTypography.bodyMedium.copyWith(
                  color: appColors.navy.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final tagId in InterestProfile.allTagIds)
                        FilterChip(
                          label: Text(_labelFor(l10n, tagId)),
                          selected: _selected.contains(tagId),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              _selected.add(tagId);
                            } else {
                              _selected.remove(tagId);
                            }
                          }),
                          selectedColor: appColors.orange.withValues(
                            alpha: 0.3,
                          ),
                          checkmarkColor: appColors.navy,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: l10n.continueButtonLabel,
                  onPressed: () => ref
                      .read(wordProgressControllerProvider.notifier)
                      .applyInterestSelection(_selected),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
