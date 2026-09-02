import 'package:flutter/material.dart';
import 'package:nonogram_daily/core/design_system/app_colors.dart';
import 'package:nonogram_daily/core/design_system/app_radius.dart';
import 'package:nonogram_daily/core/design_system/app_spacing.dart';
import 'package:nonogram_daily/core/design_system/app_typography.dart';
import 'package:nonogram_daily/core/l10n_gen/app_localizations.dart';
import 'package:nonogram_daily/presentation/settings/settings_screen.dart';
import 'package:nonogram_daily/presentation/word/wordboard/word_board_screen.dart';

/// The word game's own hub screen, its background the founder's own
/// supplied artwork (`assets/images/word_home_background_main.jfif` — a
/// revised version of an earlier photo, see below) rather than this
/// app's original vector approximation of the same "Günlük Bulmaca"
/// newspaper-desk composition.
///
/// The photo bakes in the masthead text **and** its own DİKEY/YATAY
/// decorative clue lists, so this screen draws neither itself — doing so
/// on top would visibly double them, exactly like it would for text.
/// This is a **second, replacement photo**: the first
/// (`word_home_background.jfif`) baked in calendar/settings icon
/// artwork that `BoxFit.cover` cropped inconsistently across devices
/// (see git history / CLAUDE.MD for that whole saga) — this one has no
/// baked-in icon artwork at all, so the crop-alignment workaround that
/// photo needed is gone too; default centered `BoxFit.cover` is enough
/// here. Calendar/settings stay real, visible Flutter buttons regardless
/// (see `_SquareIconButton`'s doc comment) — not because this photo
/// still has the same cropping problem, but because a photo-drawn icon
/// was never going to be as reliably tappable/accessible as a real
/// widget in the first place.
///
/// **Known trade-off, flagged rather than silently accepted**: the photo
/// is a single static asset with its Turkish masthead + clue-list text
/// baked in, so non-Turkish locales (en/de/es/fr) will still show
/// Turkish text until/unless a per-locale image is supplied — this
/// screen has no way to swap in translated text over a flattened photo.
/// The now-unreferenced `wordHomeMastheadEyebrow`/`wordHomeMastheadTitle`/
/// `wordHomeTagline` ARB keys were deliberately left in place rather than
/// deleted, in case a per-locale image (or a return to a drawn masthead)
/// revives them.
///
/// Two of the five buttons ("Liderlik Tablosu") and one bottom-nav tab
/// ("Mağaza") are visible, per the founder's reference mockup, but stay
/// non-functional "coming soon" placeholders, same as "Bulmacalar"/
/// "Başarılarım": a real leaderboard needs a backend, which conflicts
/// with this project's locked "no backend, no server" architecture, and
/// a store tab has nothing to sell under the locked ad-only monetization
/// model.
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
      backgroundColor: appColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/word_home_background_main.jfif',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Fits the masthead-clearing gap + all five cards inside
                  // whatever height this device actually gives the body
                  // (above the bottom nav), the same "compute from the
                  // real available space" approach `BoardScreen` and the
                  // crossword keyboard already use — a fixed gap here
                  // previously overflowed on the real test device, pushing
                  // the last card (and the nav bar reading as "stuck at
                  // the bottom") behind a scroll the founder's mockup
                  // never intended. The clamp's lower bound is smaller
                  // than it was for the first background photo — this
                  // one's masthead sits compactly top-left rather than
                  // centered, so cards can start higher without covering
                  // it.
                  const cardCount = 5;
                  const cardGap = AppSpacing.sm;
                  const iconRowHeight = AppSpacing.minTouchTarget;
                  const rowToCardsGap = AppSpacing.md;
                  const trailingPadding = AppSpacing.sm;
                  const estimatedCardHeight = 68.0;
                  const cardsHeight =
                      cardCount * estimatedCardHeight +
                      (cardCount - 1) * cardGap;
                  const fixedChrome =
                      iconRowHeight +
                      rowToCardsGap +
                      cardsHeight +
                      trailingPadding;
                  final mastheadGap = (constraints.maxHeight - fixedChrome)
                      .clamp(80.0, 260.0);

                  // The Material glow overscroll indicator painted a flat
                  // white band at the scroll boundary whenever a drag
                  // reached the end — jarring against the parchment photo,
                  // and confusing on a screen that (per the fit-to-height
                  // math above) isn't actually meant to need scrolling.
                  // Disabled outright rather than just relying on content
                  // fitting exactly, since a drag gesture can still trigger
                  // it briefly even when there's nothing further to reveal.
                  return ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(overscroll: false),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: trailingPadding),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _SquareIconButton(
                                icon: Icons.calendar_month_rounded,
                                tooltip: l10n.archiveTitle,
                                navy: appColors.navy,
                                background: appColors.background,
                                onPressed: () => _showComingSoon(context, l10n),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _SquareIconButton(
                                icon: Icons.settings_rounded,
                                tooltip: l10n.settingsTitle,
                                navy: appColors.navy,
                                background: appColors.background,
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: mastheadGap),
                          _ActionCard(
                            icon: Icons.grid_view_rounded,
                            title: l10n.wordHomeNewPuzzleButtonLabel,
                            subtitle: l10n.wordHomeNewPuzzleSubtitle,
                            emphasized: true,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const WordBoardScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(height: cardGap),
                          _ActionCard(
                            icon: Icons.star_rounded,
                            title: l10n.archiveTitle,
                            subtitle: l10n.wordHomeArchiveSubtitle,
                            onTap: () => _showComingSoon(context, l10n),
                          ),
                          const SizedBox(height: cardGap),
                          _ActionCard(
                            icon: Icons.emoji_events_rounded,
                            title: l10n.achievementsSectionTitle,
                            subtitle: l10n.wordHomeAchievementsSubtitle,
                            onTap: () => _showComingSoon(context, l10n),
                          ),
                          const SizedBox(height: cardGap),
                          _ActionCard(
                            icon: Icons.leaderboard_rounded,
                            title: l10n.wordHomeLeaderboardButtonLabel,
                            subtitle: l10n.wordHomeLeaderboardSubtitle,
                            onTap: () => _showComingSoon(context, l10n),
                          ),
                          const SizedBox(height: cardGap),
                          _ActionCard(
                            icon: Icons.menu_book_rounded,
                            title: l10n.settingsHowToPlayLabel,
                            subtitle: l10n.wordHomeHowToPlaySubtitle,
                            onTap: () => _showHowToPlay(context, l10n),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _WordHomeBottomNav(
        onNonHomeTap: () => _showComingSoon(context, l10n),
      ),
    );
  }
}

/// Real, visible Flutter buttons rather than relying on any icon artwork
/// baked into the background photo — the current photo
/// (`word_home_background_main.jfif`) doesn't bake in icon artwork at
/// all, but an earlier version of it did, and `BoxFit.cover` cropped
/// that inconsistently across devices (see `WordHomeScreen`'s doc
/// comment for that history). Kept as real widgets going forward on
/// principle, not just to dodge that specific bug: a photo-drawn icon
/// can never be as reliably tappable/accessible as an actual widget.
class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.tooltip,
    required this.navy,
    required this.background,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color navy;
  final Color background;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSpacing.minTouchTarget,
      height: AppSpacing.minTouchTarget,
      child: Material(
        color: navy,
        borderRadius: AppRadius.mdRadius,
        child: InkWell(
          borderRadius: AppRadius.mdRadius,
          onTap: onPressed,
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, color: background, size: 20),
          ),
        ),
      ),
    );
  }
}

/// One home-screen action row: a circular icon badge plus a title and
/// subtitle. Distinct in shape from `AppButton` (which is label+icon
/// inline, no subtitle) — kept private to this screen since nothing else
/// needs this exact layout yet; promote to `presentation/shared/` the
/// first time a second screen wants the same shape, per this project's
/// "no speculative abstraction" rule.
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    // Cream/ivory, never a flat white — matches the founder's reference
    // card look against the parchment-photo background, where a plain
    // white card read as out of place.
    final surfaceColor = emphasized ? appColors.navy : appColors.background;
    final titleColor = emphasized ? appColors.background : appColors.navy;
    final subtitleColor = emphasized
        ? appColors.background.withValues(alpha: 0.75)
        : appColors.navy.withValues(alpha: 0.55);
    final badgeColor = emphasized ? appColors.orange : appColors.navy;
    final badgeIconColor = emphasized ? appColors.navy : appColors.orange;
    final badgeRingColor = emphasized
        ? appColors.navy.withValues(alpha: 0.4)
        : appColors.orange.withValues(alpha: 0.6);
    final cardBorderColor = appColors.orange.withValues(
      alpha: emphasized ? 0.55 : 0.45,
    );

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: surfaceColor,
        borderRadius: AppRadius.lgRadius,
        elevation: emphasized ? 3 : 0,
        shadowColor: appColors.navy.withValues(alpha: 0.3),
        child: InkWell(
          borderRadius: AppRadius.lgRadius,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.smMd,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.lgRadius,
              border: Border.all(color: cardBorderColor, width: 1.4),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: badgeRingColor, width: 1.6),
                  ),
                  child: Icon(icon, color: badgeIconColor, size: 22),
                ),
                const SizedBox(width: AppSpacing.smMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTypography.labelLarge.copyWith(
                          color: titleColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WordHomeBottomNav extends StatelessWidget {
  const _WordHomeBottomNav({required this.onNonHomeTap});

  final VoidCallback onNonHomeTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appColors = context.appColors;

    return ColoredBox(
      color: appColors.navy,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: l10n.wordHomeBottomNavHomeLabel,
                selected: true,
                appColors: appColors,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: l10n.archiveTitle,
                selected: false,
                appColors: appColors,
                onTap: onNonHomeTap,
              ),
              _NavItem(
                icon: Icons.military_tech_rounded,
                label: l10n.achievementsSectionTitle,
                selected: false,
                appColors: appColors,
                onTap: onNonHomeTap,
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: l10n.statisticsTitle,
                selected: false,
                appColors: appColors,
                onTap: onNonHomeTap,
              ),
              _NavItem(
                icon: Icons.storefront_rounded,
                label: l10n.wordHomeStoreLabel,
                selected: false,
                appColors: appColors,
                onTap: onNonHomeTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.appColors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final AppColors appColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? appColors.orange
        : appColors.background.withValues(alpha: 0.55);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
