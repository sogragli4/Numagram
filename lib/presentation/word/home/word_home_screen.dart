import 'package:flutter/material.dart';
import 'package:nonogram_daily/core/design_system/app_colors.dart';
import 'package:nonogram_daily/core/design_system/app_spacing.dart';
import 'package:nonogram_daily/core/design_system/app_typography.dart';
import 'package:nonogram_daily/core/l10n_gen/app_localizations.dart';
import 'package:nonogram_daily/presentation/settings/settings_screen.dart';
import 'package:nonogram_daily/presentation/shared/app_button.dart';
import 'package:nonogram_daily/presentation/word/home/word_masthead_painter.dart';
import 'package:nonogram_daily/presentation/word/wordboard/word_board_screen.dart';

/// The word game's own hub screen, the "Günlük Bulmaca" branded home
/// referenced by the founder's mockup — sits between `GamePickerScreen`
/// (which picks a game mode) and `WordBoardScreen` (which plays one),
/// mirroring the role Nonogram's `DailyScreen` already plays for that game.
///
/// Two buttons from the original mockup are intentionally not full
/// features yet: "Bulmacalar" (archive) and "Başarılarım" (achievements)
/// both need real persisted word-game history, and that's Faz 3 — not
/// started (see CLAUDE.MD). Rather than fake data or hide the buttons
/// entirely, they stay visible and tappable and surface a clear
/// "coming soon" message, consistent with this project's standing rule of
/// flagging an unfinished gap rather than papering over it. A third
/// mockup button, "Liderlik Tablosu" (leaderboard), was dropped per the
/// founder's own explicit decision — a real leaderboard needs a backend,
/// which conflicts with the locked "no backend, no server" architecture;
/// "Başarılarım" now covers what it would have shown (personal stats),
/// so keeping both would have meant two buttons pointing at the same
/// place. The mockup's "Mağaza" bottom-nav tab was dropped outright, same
/// reasoning — no in-app purchases exist under the locked ad-only
/// monetization model.
class WordHomeScreen extends StatelessWidget {
  const WordHomeScreen({super.key});

  void _showComingSoon(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.wordHomeComingSoonMessage)));
  }

  void _showHowToPlay(BuildContext context, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.tutorialTitle),
        content: Text(l10n.wordHomeHowToPlayBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.continueButtonLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appColors = context.appColors;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: WordMastheadPainter(
                navy: appColors.navy,
                orange: appColors.orange,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.calendar_month),
                        color: appColors.background,
                        tooltip: l10n.archiveTitle,
                        onPressed: () => _showComingSoon(context, l10n),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        color: appColors.background,
                        tooltip: l10n.settingsTitle,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    l10n.wordGameTitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.displayMedium.copyWith(
                      color: appColors.background,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.wordHomeTagline,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge.copyWith(
                      color: appColors.background.withValues(alpha: 0.75),
                    ),
                  ),
                  const Spacer(flex: 2),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: l10n.wordHomeNewPuzzleButtonLabel,
                      icon: Icons.edit_note,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const WordBoardScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: l10n.archiveTitle,
                      icon: Icons.grid_view,
                      variant: AppButtonVariant.outlined,
                      onPressed: () => _showComingSoon(context, l10n),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: l10n.achievementsSectionTitle,
                      icon: Icons.emoji_events_outlined,
                      variant: AppButtonVariant.outlined,
                      onPressed: () => _showComingSoon(context, l10n),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: l10n.settingsHowToPlayLabel,
                      icon: Icons.help_outline,
                      variant: AppButtonVariant.text,
                      onPressed: () => _showHowToPlay(context, l10n),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
