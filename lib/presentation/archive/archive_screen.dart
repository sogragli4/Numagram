import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nonogram_daily/core/constants.dart';
import 'package:nonogram_daily/core/date_key.dart';
import 'package:nonogram_daily/core/injection.dart';
import 'package:nonogram_daily/core/l10n_gen/app_localizations.dart';
import 'package:nonogram_daily/presentation/daily/calendar_widget.dart';
import 'package:nonogram_daily/presentation/daily/daily_controller.dart';
import 'package:nonogram_daily/presentation/game/board_controller.dart';
import 'package:nonogram_daily/presentation/game/board_screen.dart';
import 'package:nonogram_daily/presentation/settings/settings_controller.dart';
import 'package:nonogram_daily/services/ads/ad_service.dart';

/// Any past date's daily puzzle is playable here — it's regenerated on
/// demand from the date's seed (Phase 3 spec: "the archive costs zero
/// storage"). The calendar showing completed/missed/today doubles as
/// both the Phase 3 "calendar screen" and the "archive" feature; they're
/// the same underlying data.
///
/// Phase 4: opening a *past* date counts against the free daily archive
/// limit (today's own daily puzzle is always free — it's not "archive").
class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  late DateTime _visibleMonth;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  Future<void> _openDate(DateTime date) async {
    final isPastDate = _dateOnly(date).isBefore(_dateOnly(DateTime.now()));
    if (isPastDate && !await _ensureArchiveUnlock()) return;
    if (!mounted) return;

    final puzzle = await ref.read(generateDailyPuzzleProvider).call(date);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BoardScreen(
          args: BoardArgs.daily(puzzle: puzzle, date: date),
        ),
      ),
    );
    ref.invalidate(streakForTodayProvider);
  }

  /// Returns whether opening a past-date puzzle is allowed: free under
  /// the daily cap, or unlocked by watching a rewarded ad just now.
  Future<bool> _ensureArchiveUnlock() async {
    final settingsController = ref.read(appSettingsControllerProvider.notifier);
    final settings = ref.read(appSettingsControllerProvider);
    final todayKey = formatDateKey(DateTime.now());
    final usedToday = settings.archiveUnlocksCountFor(todayKey);

    if (usedToday < GameLimits.freeArchivePuzzlesPerDay) {
      await settingsController.recordArchiveUnlock(todayKey);
      return true;
    }

    if (FeatureFlags.archiveUnlockRewardedAdEnabled) {
      final analytics = ref.read(analyticsServiceProvider);
      await analytics.logRewardedShown(placement: 'archive_unlock');
      final earned = await ref
          .read(adServiceProvider)
          .showRewarded(RewardedPlacement.archiveUnlock);
      if (earned) {
        await analytics.logRewardedCompleted(placement: 'archive_unlock');
        await settingsController.recordArchiveUnlock(todayKey);
        return true;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).archiveLimitReachedMessage,
          ),
        ),
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final streakAsync = ref.watch(streakForTodayProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.archiveTitle)),
      body: Column(
        children: [
          Expanded(
            child: streakAsync.when(
              data: (streak) => SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => _shiftMonth(-1),
                        ),
                        Text(
                          '${_visibleMonth.year}-'
                          '${_visibleMonth.month.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed:
                              DateTime(
                                _visibleMonth.year,
                                _visibleMonth.month + 1,
                              ).isAfter(DateTime.now())
                              ? null
                              : () => _shiftMonth(1),
                        ),
                      ],
                    ),
                    CalendarWidget(
                      month: _visibleMonth,
                      completedDates: streak.completedDates,
                      today: DateTime.now(),
                      onDayTap: _openDate,
                    ),
                  ],
                ),
              ),
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
