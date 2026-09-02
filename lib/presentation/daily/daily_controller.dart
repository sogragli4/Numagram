import 'package:nonogram_daily/core/injection.dart';
import 'package:nonogram_daily/domain/entities/streak_record.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'daily_controller.g.dart';

@riverpod
Future<StreakRecord> streakForToday(Ref ref) {
  return ref.watch(streakRepositoryProvider).getStreak(today: DateTime.now());
}
