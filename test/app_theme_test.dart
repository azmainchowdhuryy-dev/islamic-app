import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/theme/app_colors.dart';
import 'package:islamic_app/core/theme/app_surface_styles.dart';
import 'package:islamic_app/core/theme/app_theme.dart';

void main() {
  test('Deep Teal palette keeps the requested exact hex values', () {
    expect(AppColors.heroSurface, const Color(0xFF0B3B36));
    expect(AppColors.middleSurface, const Color(0xFF132120));
    expect(AppColors.bottomSurface, const Color(0xFF0E1716));
    expect(AppColors.activeSurface, const Color(0xFF1A4D46));
    expect(AppColors.primaryAccent, const Color(0xFF26A69A));
    expect(AppColors.primaryText, const Color(0xFFFFFFFF));
    expect(AppColors.secondaryText, const Color(0xFFA3B8B5));
    expect(AppColors.subtleBorder, const Color(0xFF233533));
    expect(AppColors.iconBadge, const Color(0xFF162E2B));
    expect(AppColors.warmAmber, const Color(0xFFE67E22));
    expect(AppColors.progressRing, const Color(0xFF8E2430));
  });

  test('dark theme maps dashboard surfaces and navigation colours', () {
    final theme = AppTheme.dark;

    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AppColors.middleSurface);
    expect(theme.colorScheme.primary, AppColors.primaryAccent);
    expect(theme.colorScheme.surface, AppColors.middleSurface);
    expect(theme.navigationBarTheme.backgroundColor, AppColors.bottomSurface);
    expect(theme.navigationBarTheme.indicatorColor, AppColors.activeSurface);
    expect(
      theme.bottomNavigationBarTheme.selectedItemColor,
      AppColors.primaryAccent,
    );
    expect(
      theme.bottomNavigationBarTheme.unselectedItemColor,
      AppColors.secondaryText,
    );
  });

  test('hero, middle card, active row and feature badge helpers use palette', () {
    final hero = AppSurfaceStyles.hero();
    final middle = AppSurfaceStyles.middleCard();
    final active = AppSurfaceStyles.activeRow();
    final badge = AppSurfaceStyles.featureIconBadge();

    expect(hero.color, AppColors.heroSurface);
    expect(hero.borderRadius, BorderRadius.vertical(bottom: Radius.circular(24)));
    expect(middle.color, AppColors.middleSurface);
    expect(active.color, AppColors.activeSurface);
    expect(badge.color, AppColors.iconBadge);
    expect(badge.shape, BoxShape.circle);
  });
}
