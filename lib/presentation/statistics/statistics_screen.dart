import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nonogram_daily/core/constants.dart';
import 'package:nonogram_daily/core/injection.dart';
import 'package:nonogram_daily/core/l10n_gen/app_localizations.dart';
import 'package:nonogram_daily/domain/entities/achievement.dart';
import 'package:nonogram_daily/domain/entities/statistics.dart';
import 'package:nonogram_daily/domain/usecases/evaluate_achievements.dart';
import 'package:nonogram_daily/presentation/daily/daily_controller.dart';
import 'package:nonogram_daily/presentation/statistics/statistics_controller.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statsAsync = ref.watch(statisticsProvider);
    final longestStreak =
        ref.watch(streakForTodayProvider).value?.longestStreak ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statisticsTitle)),
      bottomNavigationBar: FeatureFlags.bannerAdEnabled
          ? ref.watch(adServiceProvider).buildBanner()
          : null,
      body: statsAsync.when(
        data: (stats) =>
            _StatisticsBody(stats: stats, longestStreak: longestStreak),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('$error')),
      ),
    );
  }
}

class _StatisticsBody extends StatelessWidget {
  const _StatisticsBody({required this.stats, required this.longestStreak});

  final Statistics stats;
  final int longestStreak;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final achievements = evaluateAchievements(
      statistics: stats,
      longestStreak: longestStreak,
    );
    final sizeEntries = stats.averageSecondsBySize.entries.toList()
      ..sort((a, b) => a.key.cellCount.compareTo(b.key.cellCount));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.achievementsSectionTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final achievement in achievements)
              _AchievementBadge(achievement: achievement),
          ],
        ),
        const SizedBox(height: 16),
        if (stats.totalSolved == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(l10n.statsEmptyMessage, textAlign: TextAlign.center),
          )
        else ...[
          const Divider(),
          _StatTile(
            label: l10n.statsTotalSolvedLabel,
            value: '${stats.totalSolved}',
          ),
          _StatTile(
            label: l10n.statsPerfectCountLabel,
            value: '${stats.perfectCount}',
          ),
          const SizedBox(height: 16),
          Text(
            l10n.statsAverageTimeSectionTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final entry in sizeEntries)
            _StatTile(
              label: '${entry.key.width}×${entry.key.height}',
              value: _formatSeconds(entry.value),
            ),
        ],
      ],
    );
  }

  String _formatSeconds(double seconds) {
    final total = seconds.round();
    final minutes = total ~/ 60;
    final remaining = total % 60;
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Text(value, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

(IconData, String, String) _presentationFor(
  AppLocalizations l10n,
  AchievementId id,
) => switch (id) {
  AchievementId.firstPuzzle => (
    Icons.flag_outlined,
    l10n.achievementFirstPuzzleTitle,
    l10n.achievementFirstPuzzleDescription,
  ),
  AchievementId.tenPuzzles => (
    Icons.trending_up,
    l10n.achievementTenPuzzlesTitle,
    l10n.achievementTenPuzzlesDescription,
  ),
  AchievementId.fiftyPuzzles => (
    Icons.local_fire_department_outlined,
    l10n.achievementFiftyPuzzlesTitle,
    l10n.achievementFiftyPuzzlesDescription,
  ),
  AchievementId.hundredPuzzles => (
    Icons.military_tech_outlined,
    l10n.achievementHundredPuzzlesTitle,
    l10n.achievementHundredPuzzlesDescription,
  ),
  AchievementId.firstPerfect => (
    Icons.star_border,
    l10n.achievementFirstPerfectTitle,
    l10n.achievementFirstPerfectDescription,
  ),
  AchievementId.tenPerfect => (
    Icons.star,
    l10n.achievementTenPerfectTitle,
    l10n.achievementTenPerfectDescription,
  ),
  AchievementId.threeDayStreak => (
    Icons.bolt_outlined,
    l10n.achievementThreeDayStreakTitle,
    l10n.achievementThreeDayStreakDescription,
  ),
  AchievementId.sevenDayStreak => (
    Icons.calendar_view_week_outlined,
    l10n.achievementSevenDayStreakTitle,
    l10n.achievementSevenDayStreakDescription,
  ),
  AchievementId.thirtyDayStreak => (
    Icons.calendar_month_outlined,
    l10n.achievementThirtyDayStreakTitle,
    l10n.achievementThirtyDayStreakDescription,
  ),
  AchievementId.bigThinker => (
    Icons.grid_view_outlined,
    l10n.achievementBigThinkerTitle,
    l10n.achievementBigThinkerDescription,
  ),
  AchievementId.goBig => (
    Icons.crop_square_outlined,
    l10n.achievementGoBigTitle,
    l10n.achievementGoBigDescription,
  ),
};

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (icon, title, description) = _presentationFor(l10n, achievement.id);
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 104,
      child: Opacity(
        opacity: achievement.isUnlocked ? 1 : 0.4,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: achievement.isUnlocked
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                achievement.isUnlocked ? icon : Icons.lock_outline,
                color: achievement.isUnlocked
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
