import 'package:nonogram_daily/core/injection.dart';
import 'package:nonogram_daily/domain/entities/statistics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'statistics_controller.g.dart';

@riverpod
Future<Statistics> statistics(Ref ref) =>
    ref.watch(streakRepositoryProvider).getStatistics();
