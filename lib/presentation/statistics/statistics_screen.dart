import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nonogram_daily/core/constants.dart';
import 'package:nonogram_daily/core/injection.dart';
import 'package:nonogram_daily/core/l10n_gen/app_localizations.dart';
import 'package:nonogram_daily/presentation/statistics/statistics_controller.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statsAsync = ref.watch(statisticsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statisticsTitle)),
      bottomNavigationBar: FeatureFlags.bannerAdEnabled
          ? ref.watch(adServiceProvider).buildBanner()
          : null,
      body: statsAsync.when(
        data: (stats) {
          if (stats.totalSolved == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.statsEmptyMessage,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final sizeEntries = stats.averageSecondsBySize.entries.toList()
            ..sort((a, b) => a.key.cellCount.compareTo(b.key.cellCount));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('$error')),
      ),
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
