import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

class AppTheme {
  static const Color deepGreen = Color(0xFF0F5132);
  static const Color green = Color(0xFF198754);

  static ThemeData _buildLight() {
    final scheme = ColorScheme.fromSeed(
      seedColor: green,
      primary: deepGreen,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData get light => _buildLight();

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryAccent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.primaryAccent,
      onPrimary: AppColors.primaryText,
      secondary: AppColors.primaryAccent,
      onSecondary: AppColors.primaryText,
      surface: AppColors.middleSurface,
      onSurface: AppColors.primaryText,
      onSurfaceVariant: AppColors.secondaryText,
      surfaceContainerLowest: AppColors.bottomSurface,
      surfaceContainerLow: AppColors.bottomSurface,
      surfaceContainer: AppColors.middleSurface,
      surfaceContainerHigh: AppColors.activeSurface,
      surfaceContainerHighest: AppColors.iconBadge,
      outline: AppColors.subtleBorder,
      outlineVariant: AppColors.subtleBorder,
      error: AppColors.progressRing,
      onError: AppColors.primaryText,
      primaryContainer: AppColors.activeSurface,
      onPrimaryContainer: AppColors.primaryText,
      secondaryContainer: AppColors.iconBadge,
      onSecondaryContainer: AppColors.primaryText,
      tertiary: AppColors.warmAmber,
      onTertiary: AppColors.bottomSurface,
      tertiaryContainer: AppColors.iconBadge,
      onTertiaryContainer: AppColors.primaryText,
      surfaceTint: Colors.transparent,
    );

    return ThemeData.dark().copyWith(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.middleSurface,
      canvasColor: AppColors.bottomSurface,
      cardColor: AppColors.middleSurface,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.heroSurface,
        foregroundColor: AppColors.primaryText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.middleSurface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.subtleBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.subtleBorder,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.secondaryText),
      textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: AppColors.primaryText,
            displayColor: AppColors.primaryText,
          ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bottomSurface,
        selectedItemColor: AppColors.primaryAccent,
        unselectedItemColor: AppColors.secondaryText,
        selectedIconTheme: IconThemeData(color: AppColors.primaryAccent),
        unselectedIconTheme: IconThemeData(color: AppColors.secondaryText),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bottomSurface,
        indicatorColor: AppColors.activeSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 76,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.primaryAccent
                : AppColors.secondaryText,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primaryAccent
                : AppColors.secondaryText,
            size: 24,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: AppColors.primaryText,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryAccent,
        linearTrackColor: AppColors.subtleBorder,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.iconBadge,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.subtleBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.subtleBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryAccent),
        ),
      ),
      chipTheme: ThemeData.dark().chipTheme.copyWith(
            backgroundColor: AppColors.iconBadge,
            selectedColor: AppColors.activeSurface,
            side: const BorderSide(color: AppColors.subtleBorder),
            labelStyle: const TextStyle(color: AppColors.primaryText),
            secondaryLabelStyle:
                const TextStyle(color: AppColors.primaryText),
          ),
    );
  }
}
