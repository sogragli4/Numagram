import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nonogram_daily/core/l10n_gen/app_localizations.dart';
import 'package:nonogram_daily/core/theme.dart';
import 'package:nonogram_daily/presentation/daily/daily_controller.dart';
import 'package:nonogram_daily/presentation/onboarding/tutorial_screen.dart';
import 'package:nonogram_daily/presentation/settings/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    int hour,
    int minute,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
    if (picked == null) return;
    await ref
        .read(appSettingsControllerProvider.notifier)
        .setNotificationTime(
          hour: picked.hour,
          minute: picked.minute,
          title: l10n.dailyReminderNotificationTitle,
          body: l10n.dailyReminderNotificationBody,
        );
  }

  String _themeLabel(AppLocalizations l10n, AppColorTheme theme) =>
      switch (theme) {
        AppColorTheme.classic => l10n.themeClassicLabel,
        AppColorTheme.sunset => l10n.themeSunsetLabel,
        AppColorTheme.forest => l10n.themeForestLabel,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsControllerProvider);
    final controller = ref.read(appSettingsControllerProvider.notifier);
    final longestStreak =
        ref.watch(streakForTodayProvider).value?.longestStreak ?? 0;
    final selectedTheme = AppColorTheme.fromId(settings.selectedThemeId);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ListTile(title: Text(l10n.themeSectionTitle)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                for (final theme in AppColorTheme.values)
                  _ThemeSwatch(
                    theme: theme,
                    label: _themeLabel(l10n, theme),
                    selected: theme == selectedTheme,
                    unlocked: theme.isUnlockedAt(longestStreak),
                    lockedHint: l10n.themeLockedHint(theme.requiredStreak),
                    onTap: () => controller.selectColorTheme(theme.id),
                  ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.settingsHowToPlayLabel),
            leading: const Icon(Icons.school_outlined),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const TutorialScreen()),
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(l10n.colorblindPaletteLabel),
            value: settings.colorblindPalette,
            onChanged: (value) =>
                controller.setColorblindPalette(enabled: value),
          ),
          const Divider(),
          ListTile(title: Text(l10n.settingsNotificationsSectionTitle)),
          SwitchListTile(
            title: Text(l10n.settingsNotificationsToggleLabel),
            subtitle: settings.hasCompletedFirstPuzzle
                ? null
                : Text(l10n.settingsNotificationsLockedHint),
            value: settings.notificationsEnabled,
            onChanged: settings.hasCompletedFirstPuzzle
                ? (value) => controller.setNotificationsEnabled(
                    enabled: value,
                    title: l10n.dailyReminderNotificationTitle,
                    body: l10n.dailyReminderNotificationBody,
                  )
                : null,
          ),
          if (settings.notificationsEnabled)
            ListTile(
              title: Text(l10n.settingsNotificationTimeLabel),
              trailing: Text(
                '${settings.notificationHour.toString().padLeft(2, '0')}:'
                '${settings.notificationMinute.toString().padLeft(2, '0')}',
              ),
              onTap: () => _pickTime(
                context,
                ref,
                l10n,
                settings.notificationHour,
                settings.notificationMinute,
              ),
            ),
        ],
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.theme,
    required this.label,
    required this.selected,
    required this.unlocked,
    required this.lockedHint,
    required this.onTap,
  });

  final AppColorTheme theme;
  final String label;
  final bool selected;
  final bool unlocked;
  final String lockedHint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: InkWell(
        onTap: unlocked ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: unlocked ? 1 : 0.4,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.seedColor,
                  shape: BoxShape.circle,
                  border: selected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: 3,
                        )
                      : null,
                ),
                child: unlocked
                    ? null
                    : const Icon(Icons.lock, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center),
              if (!unlocked)
                Text(
                  lockedHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
