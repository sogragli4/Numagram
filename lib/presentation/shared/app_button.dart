import 'package:flutter/material.dart';
import 'package:nonogram_daily/core/design_system/app_colors.dart';
import 'package:nonogram_daily/core/design_system/app_radius.dart';
import 'package:nonogram_daily/core/design_system/app_spacing.dart';

enum AppButtonVariant { filled, outlined, text }

/// The app's one button widget — every new screen should reach for this
/// instead of `FilledButton`/`OutlinedButton`/`TextButton` directly, so a
/// future style change (padding, icon gap, shape) happens in one place.
/// [AppButtonVariant.filled] is always the [AppColors.orange] brand
/// color — "primary actions use the orange brand color" (development
/// rules) — rather than the ambient `ColorScheme.primary`, which stays
/// per-game (Nonogram's own unlockable seed themes; see `AppColorTheme`).
/// `outlined`/`text` stay neutral, on the ambient `ColorScheme`, for
/// secondary actions.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.variant = AppButtonVariant.filled,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(label),
            ],
          );
    const shape = RoundedRectangleBorder(borderRadius: AppRadius.mdRadius);

    return switch (variant) {
      AppButtonVariant.filled => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: context.appColors.orange,
          foregroundColor: context.appColors.navy,
          shape: shape,
        ),
        child: child,
      ),
      AppButtonVariant.outlined => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(shape: shape),
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(shape: shape),
        child: child,
      ),
    };
  }
}
