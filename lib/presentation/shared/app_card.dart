import 'package:flutter/material.dart';
import 'package:nonogram_daily/core/design_system/app_colors.dart';
import 'package:nonogram_daily/core/design_system/app_radius.dart';
import 'package:nonogram_daily/core/design_system/app_spacing.dart';

/// The app's one card surface — a tonal, optionally-tappable container
/// with consistent radius and padding, low elevation (flat, not a
/// heavy shadow — "premium/minimal", not skeuomorphic). Every new screen
/// should reach for this instead of a raw `Card`/`Material`+`InkWell`
/// pair. Color comes from [AppColors.surface], so it adapts to
/// light/dark automatically.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.surface,
      borderRadius: AppRadius.mdRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
