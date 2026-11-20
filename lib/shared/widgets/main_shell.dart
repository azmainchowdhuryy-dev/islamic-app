import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/navigation/navigation_provider.dart';
import '../../features/hadith/screens/hadith_dua_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/settings/screens/more_screen.dart';
import '../../features/tasbih/screens/tasbih_screen.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider).t;
    final index = ref.watch(mainNavigationIndexProvider);
    return Scaffold(
      body: IndexedStack(index: index, children: const [
        HomeScreen(),
        HadithDuaScreen(),
        TasbihScreen(),
        MoreScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => ref.read(mainNavigationIndexProvider.notifier).state = i,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), label: t('home')),
          NavigationDestination(icon: const Icon(Icons.menu_book_outlined), label: t('hadith_dua')),
          NavigationDestination(icon: const Icon(Icons.touch_app_outlined), label: t('tasbih')),
          NavigationDestination(icon: const Icon(Icons.more_horiz), label: t('more')),
        ],
      ),
    );
  }
}
