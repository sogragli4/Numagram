import 'package:flutter/material.dart';
import 'package:nonogram_daily/core/design_system/app_colors.dart';
import 'package:nonogram_daily/core/design_system/app_spacing.dart';
import 'package:nonogram_daily/core/design_system/app_typography.dart';
import 'package:nonogram_daily/core/l10n_gen/app_localizations.dart';
import 'package:nonogram_daily/presentation/daily/daily_screen.dart';
import 'package:nonogram_daily/presentation/shared/app_card.dart';
import 'package:nonogram_daily/presentation/word/wordboard/word_board_screen.dart';

/// The app's entry point once both game modes exist — two cards, each
/// opening that game's own flow. Replaces the direct-to-`DailyScreen`
/// jump `_HomeRouter` used before this feature (CLAUDE.MD, "Kelime
/// Bulmacası" bölüm 9 — same app, second mode).
class GamePickerScreen extends StatelessWidget {
  const GamePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(title: Text(l10n.gamePickerTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            alignment: WrapAlignment.center,
            children: [
              _GameCard(
                icon: Icons.grid_on,
                label: l10n.appTitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const DailyScreen()),
                ),
              ),
              _GameCard(
                icon: Icons.edit_note,
                label: l10n.wordGameTitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const WordBoardScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: AppCard(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: context.appColors.orange),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
