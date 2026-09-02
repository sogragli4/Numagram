import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nonogram_daily/core/date_key.dart';
import 'package:nonogram_daily/core/injection.dart';
import 'package:nonogram_daily/domain/entities/streak_record.dart';
import 'package:nonogram_daily/presentation/settings/settings_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'daily_controller.g.dart';

/// Combines completed dates from `StreakRepository` with the streak-freeze
/// dates from `AppSettings` (see `domain/usecases/streak_freeze.dart`) —
/// `StreakRepository.getStreak` deliberately stays freeze-unaware, since a
/// repository should be about completions, not settings-driven freeze
/// state; this is the one place both are combined for display.
@riverpod
Future<StreakRecord> streakForToday(Ref ref) async {
  final completedDates = await ref
      .watch(streakRepositoryProvider)
      .getCompletedDates();
  final frozenDateKeys = ref.watch(
    appSettingsControllerProvider.select((s) => s.frozenDateKeys),
  );
  return StreakRecord.compute(
    completedDates: completedDates,
    frozenDates: frozenDateKeys.map(parseDateKey).toSet(),
    today: DateTime.now(),
  );
}
