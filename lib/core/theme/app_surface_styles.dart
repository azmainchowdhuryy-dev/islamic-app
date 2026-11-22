import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Reusable surfaces for the layered prayer and utility dashboard.
abstract final class AppSurfaceStyles {
  static BoxDecoration hero({double bottomRadius = 24}) => BoxDecoration(
        color: AppColors.heroSurface,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(bottomRadius),
        ),
      );

  static BoxDecoration middleCard({double radius = 18}) => BoxDecoration(
        color: AppColors.middleSurface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.subtleBorder),
      );

  static BoxDecoration activeRow({double radius = 14}) => BoxDecoration(
        color: AppColors.activeSurface,
        borderRadius: BorderRadius.circular(radius),
      );

  static BoxDecoration featureIconBadge() => const BoxDecoration(
        color: AppColors.iconBadge,
        shape: BoxShape.circle,
      );
}
