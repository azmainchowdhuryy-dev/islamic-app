import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../features/hadith/screens/hadith_dua_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/settings/screens/more_screen.dart';
import '../../features/tasbih/screens/tasbih_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider).t;
    return Scaffold(
      body: IndexedStack(index: _index, children: const [
        HomeScreen(),
        HadithDuaScreen(),
        TasbihScreen(),
        MoreScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
