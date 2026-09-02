import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nonogram_daily/core/constants.dart';
import 'package:nonogram_daily/core/injection.dart';
import 'package:nonogram_daily/core/l10n_gen/app_localizations.dart';
import 'package:nonogram_daily/domain/entities/streak_record.dart';
import 'package:nonogram_daily/presentation/archive/archive_screen.dart';
import 'package:nonogram_daily/presentation/daily/daily_controller.dart';
import 'package:nonogram_daily/presentation/freeplay/free_play_screen.dart';
import 'package:nonogram_daily/presentation/game/board_controller.dart';
import 'package:nonogram_daily/presentation/game/board_screen.dart';
import 'package:nonogram_daily/presentation/settings/settings_controller.dart';
import 'package:nonogram_daily/presentation/settings/settings_screen.dart';
import 'package:nonogram_daily/presentation/statistics/statistics_screen.dart';

/// Home screen: today's streak, the entry point into today's puzzle, and
/// navigation to the archive, free play, statistics, and settings.
class DailyScreen extends ConsumerWidget {
  const DailyScreen({super.key});

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _playToday(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final today = DateTime.now();
    final wasCompletedBefore = await ref
        .read(streakForTodayProvider.future)
        .then((s) => s.completedDates.contains(_dateOnly(today)));

    final puzzle = await ref.read(generateDailyPuzzleProvider).call(today);
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BoardScreen(
          args: BoardArgs.daily(puzzle: puzzle, date: today),
        ),
      ),
    );

    ref.invalidate(streakForTodayProvider);
    final isCompletedNow = await ref
        .read(streakForTodayProvider.future)
        .then((s) => s.completedDates.contains(_dateOnly(today)));

    if (!wasCompletedBefore && isCompletedNow) {
      final settings = ref.read(appSettingsControllerProvider);
      if (!settings.hasCompletedFirstPuzzle) {
        await ref
            .read(appSettingsControllerProvider.notifier)
            .markFirstPuzzleCompleted();
        if (context.mounted) {
          // ignore: use_build_context_synchronously, reason: guarded by mounted check above
          await _promptEnableNotifications(context, ref, l10n);
        }
      }
    }
  }

  Future<void> _promptEnableNotifications(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsNotificationsSectionTitle),
        content: Text(l10n.enableNotificationsPromptBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.notNowButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.settingsNotificationsToggleLabel),
          ),
        ],
      ),
    );
    if (accepted != true) return;

    final granted = await ref
        .read(notificationServiceProvider)
        .requestPermission();
    if (!granted) return;
    await ref
        .read(appSettingsControllerProvider.notifier)
        .setNotificationsEnabled(
          enabled: true,
          title: l10n.dailyReminderNotificationTitle,
          body: l10n.dailyReminderNotificationBody,
        );
  }

  /// Detects a streak change since it was last observed and logs
  /// `streak_extended` / `streak_broken` accordingly — the only place in
  /// the app both values are available together.
  void _trackStreakChange(WidgetRef ref, AsyncValue<StreakRecord>? next) {
    final streak = next?.value;
    if (streak == null) return;
    final settings = ref.read(appSettingsControllerProvider);
    if (streak.currentStreak == settings.lastKnownStreak) return;

    final analytics = ref.read(analyticsServiceProvider);
    if (streak.currentStreak > settings.lastKnownStreak &&
        streak.currentStreak > 0) {
      unawaited(analytics.logStreakExtended(streak: streak.currentStreak));
    } else if (streak.currentStreak == 0 && settings.lastKnownStreak > 0) {
      unawaited(
        analytics.logStreakBroken(previousStreak: settings.lastKnownStreak),
      );
    }
    unawaited(
      ref
          .read(appSettingsControllerProvider.notifier)
          .setLastKnownStreak(streak.currentStreak),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final streakAsync = ref.watch(streakForTodayProvider);
    ref.listen<AsyncValue<StreakRecord>>(
      streakForTodayProvider,
      (previous, next) => _trackStreakChange(ref, next),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.statisticsTitle,
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const StatisticsScreen()),
            ),
          ),
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: streakAsync.when(
              data: (streak) {
                final today = _dateOnly(DateTime.now());
                final completedToday = streak.completedDates.contains(today);
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.streakLabel(streak.currentStreak),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(l10n.longestStreakLabel(streak.longestStreak)),
                      const SizedBox(height: 32),
                      if (completedToday)
                        Text(l10n.todayCompletedLabel)
                      else
                        FilledButton(
                          onPressed: () => _playToday(context, ref, l10n),
                          child: Text(l10n.playTodayButtonLabel),
                        ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ArchiveScreen(),
                          ),
                        ),
                        child: Text(l10n.archiveTitle),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const FreePlayScreen(),
                          ),
                        ),
                        child: Text(l10n.freePlayTitle),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('$error')),
            ),
          ),
          if (FeatureFlags.bannerAdEnabled)
            ref.watch(adServiceProvider).buildBanner(),
        ],
      ),
    );
  }
}
