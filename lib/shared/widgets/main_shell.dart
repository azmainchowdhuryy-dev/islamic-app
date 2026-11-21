import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/navigation/navigation_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../features/hadith/screens/hadith_dua_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/settings/screens/more_screen.dart';
import '../../features/tools/screens/features_screen.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider).t;
    final index = ref.watch(mainNavigationIndexProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final navigationBackground =
        isDark ? AppColors.bottomSurface : scheme.surface;
    final navigationIndicator =
        isDark ? AppColors.activeSurface : scheme.primaryContainer;
    final selectedNavigationColor =
        isDark ? AppColors.primaryAccent : scheme.primary;
    final unselectedNavigationColor =
        isDark ? AppColors.secondaryText : scheme.onSurfaceVariant;
    return Scaffold(
      body: IndexedStack(index: index, children: const [
        HomeScreen(),
        FeaturesScreen(),
        HadithDuaScreen(section: HadithDuaSection.hadith),
        HadithDuaScreen(section: HadithDuaSection.dua),
        MoreScreen(),
      ]),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: navigationBackground,
          indicatorColor: navigationIndicator,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 76,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? selectedNavigationColor
                  : unselectedNavigationColor,
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? selectedNavigationColor
                  : unselectedNavigationColor,
              size: 24,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) =>
              ref.read(mainNavigationIndexProvider.notifier).state = i,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: t('home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.apps_outlined),
              selectedIcon: const Icon(Icons.apps),
              label: t('features'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book),
              label: t('hadith'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.volunteer_activism_outlined),
              selectedIcon: const Icon(Icons.volunteer_activism),
              label: t('dua'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: t('more'),
            ),
          ],
        ),
      ),
    );
  }
}
