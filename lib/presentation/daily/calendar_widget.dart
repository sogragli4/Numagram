import 'package:flutter/material.dart';
import 'package:nonogram_daily/core/l10n_gen/app_localizations.dart';

/// A month grid of days, colour-coded completed / missed / today, driving
/// the archive screen. Tapping a playable day (today or any day in the
/// past) invokes [onDayTap]; future days are inert.
class CalendarWidget extends StatelessWidget {
  const CalendarWidget({
    required this.month,
    required this.completedDates,
    required this.today,
    required this.onDayTap,
    super.key,
  });

  final DateTime month;
  final Set<DateTime> completedDates;
  final DateTime today;
  final void Function(DateTime date) onDayTap;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final firstOfMonth = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // DateTime.weekday: Monday=1..Sunday=7. Blank cells before day 1.
    final leadingBlanks = firstOfMonth.weekday % 7;
    final todayOnly = _dateOnly(today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          children: [
            for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
            for (var day = 1; day <= daysInMonth; day++)
              _DayCell(
                date: DateTime(month.year, month.month, day),
                isToday: DateTime(month.year, month.month, day) == todayOnly,
                isCompleted: completedDates.contains(
                  DateTime(month.year, month.month, day),
                ),
                isPlayable: !DateTime(
                  month.year,
                  month.month,
                  day,
                ).isAfter(todayOnly),
                onTap: onDayTap,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          children: [
            _Legend(
              color: colorScheme.primary,
              label: l10n.calendarLegendCompleted,
            ),
            _Legend(color: colorScheme.error, label: l10n.calendarLegendMissed),
            _Legend(
              color: colorScheme.tertiary,
              label: l10n.calendarLegendToday,
            ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isToday,
    required this.isCompleted,
    required this.isPlayable,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday;
  final bool isCompleted;
  final bool isPlayable;
  final void Function(DateTime date) onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Color background;
    Color foreground;
    if (isCompleted) {
      background = colorScheme.primary;
      foreground = colorScheme.onPrimary;
    } else if (!isPlayable) {
      background = Colors.transparent;
      foreground = colorScheme.onSurface.withValues(alpha: 0.3);
    } else {
      background = colorScheme.errorContainer.withValues(alpha: 0.4);
      foreground = colorScheme.onSurface;
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: background,
        shape: CircleBorder(
          side: isToday
              ? BorderSide(color: colorScheme.tertiary, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: isPlayable ? () => onTap(date) : null,
          child: Center(
            child: Text('${date.day}', style: TextStyle(color: foreground)),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
