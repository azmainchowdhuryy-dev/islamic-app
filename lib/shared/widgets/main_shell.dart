import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/localization/app_strings.dart';
import '../../core/navigation/navigation_provider.dart';
import '../../core/navigation/noor_navigator.dart';
import '../../core/services/noor_notification_service.dart';
import '../../core/services/prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../features/hadith/screens/hadith_dua_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/settings/screens/more_screen.dart';
import '../../features/tools/screens/features_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  Timer? _prayerPromptTimer;
  Timer? _adhkarPromptTimer;
  bool _promptVisible = false;

  static const _acceptedKey = 'prayer_notification_prompt_accepted';
  static const _nextPromptKey = 'prayer_notification_prompt_next_at';
  static const _initialDelay = Duration(minutes: 2);
  static const _repeatDelay = Duration(days: 7);
  static const _adhkarAcceptedKey = 'adhkar_notification_prompt_accepted';
  static const _adhkarNextPromptKey = 'adhkar_notification_prompt_next_at';
  static const _firstOpenKey = 'noor_first_open_at';
  static const _adhkarInitialDelay = Duration(days: 3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _schedulePrayerNotificationPrompt();
        _scheduleAdhkarNotificationPrompt();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _prayerPromptTimer?.cancel();
    _adhkarPromptTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _schedulePrayerNotificationPrompt();
    } else {
      _promptTimer?.cancel();
      _promptTimer = null;
    }
  }

  void _schedulePrayerNotificationPrompt() {
    _prayerPromptTimer?.cancel();
    _prayerPromptTimer = null;
    if (!mounted || _promptVisible) return;

    final prefs = ref.read(sharedPrefsProvider);
    if (prefs.getBool(_acceptedKey) == true ||
        prefs.getBool('notifications_prayer_enabled') == true) {
      return;
    }

    final savedDue = prefs.getInt(_nextPromptKey);
    final now = DateTime.now();
    final due = savedDue == null
        ? now.add(_initialDelay)
        : DateTime.fromMillisecondsSinceEpoch(savedDue);
    final delay = due.difference(now);

    if (delay <= Duration.zero) {
      _prayerPromptTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) _showPrayerNotificationPrompt();
      });
    } else {
      _prayerPromptTimer = Timer(delay, () {
        if (mounted) _showPrayerNotificationPrompt();
      });
    }
  }

  Future<void> _showPrayerNotificationPrompt() async {
    if (!mounted || _promptVisible) return;
    final prefs = ref.read(sharedPrefsProvider);
    if (prefs.getBool(_acceptedKey) == true ||
        prefs.getBool('notifications_prayer_enabled') == true) {
      return;
    }

    _promptVisible = true;
    final lang = ref.read(stringsProvider).lang;
    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.notifications_active_outlined, size: 34),
        title: Text(lang == 'bn'
            ? 'নামাজের সময় নোটিফিকেশন চালু করবেন?'
            : 'Turn on prayer time notifications?'),
        content: Text(lang == 'bn'
            ? 'প্রতিটি ওয়াক্ত শুরু হলে Noor আপনাকে নোটিফিকেশনের মাধ্যমে জানাবে। চাইলে সেটিংস থেকেও পরে এটি পরিবর্তন করতে পারবেন।'
            : 'Noor can notify you when each of the five daily prayer times begins. You can change this later in Settings.'),
        actions: [
          TextButton(
            key: const Key('prayer_notification_prompt_later'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(lang == 'bn' ? 'এখন নয়' : 'Not now'),
          ),
          FilledButton(
            key: const Key('prayer_notification_prompt_agree'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(lang == 'bn' ? 'চালু করুন' : 'Turn on'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    _promptVisible = false;

    if (agreed == true) {
      final granted =
          await NoorNotificationService.instance.requestPermission();
      if (!mounted) return;
      if (granted) {
        await prefs.setBool('notifications_prayer_enabled', true);
        await prefs.setBool(_acceptedKey, true);
        ref.read(notificationSettingsRevisionProvider.notifier).state++;
        await prefs.remove(_nextPromptKey);
        await NoorNotificationService.instance.syncFromPreferences(prefs);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang == 'bn'
                ? 'নামাজের সময়ের নোটিফিকেশন চালু হয়েছে।'
                : 'Prayer time notifications are enabled.'),
          ),
        );
      } else {
        await _scheduleNextPrompt(prefs);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang == 'bn'
                ? 'নোটিফিকেশন অনুমতি পাওয়া যায়নি। ৭ দিন পর আবার জিজ্ঞেস করা হবে।'
                : 'Notification permission was not granted. We will ask again in 7 days.'),
          ),
        );
      }
    } else {
      await _scheduleNextPrompt(prefs);
    }
  }


  void _scheduleAdhkarNotificationPrompt() {
    if (!mounted || _promptVisible) return;
    final prefs = ref.read(sharedPrefsProvider);
    if (prefs.getBool(_adhkarAcceptedKey) == true ||
        prefs.getBool('notifications_adhkar_enabled') == true) return;
    final now = DateTime.now();
    final firstOpenMs = prefs.getInt(_firstOpenKey);
    final firstOpen = firstOpenMs == null
        ? now
        : DateTime.fromMillisecondsSinceEpoch(firstOpenMs);
    if (firstOpenMs == null) {
      prefs.setInt(_firstOpenKey, now.millisecondsSinceEpoch);
    }
    final savedDue = prefs.getInt(_adhkarNextPromptKey);
    final due = savedDue == null
        ? firstOpen.add(_adhkarInitialDelay)
        : DateTime.fromMillisecondsSinceEpoch(savedDue);
    final delay = due.difference(now);
    _adhkarPromptTimer?.cancel();
    _adhkarPromptTimer = Timer(
      delay.isNegative ? Duration.zero : delay,
      () { if (mounted) _showAdhkarNotificationPrompt(); },
    );
  }

  Future<void> _showAdhkarNotificationPrompt() async {
    if (!mounted || _promptVisible) return;
    final prefs = ref.read(sharedPrefsProvider);
    if (prefs.getBool(_adhkarAcceptedKey) == true ||
        prefs.getBool('notifications_adhkar_enabled') == true) return;
    _promptVisible = true;
    final lang = ref.read(stringsProvider).lang;
    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.wb_twilight_rounded, size: 34),
        title: Text(lang == 'bn'
            ? 'সকাল-সন্ধ্যার আমলের রিমাইন্ডার চালু করবেন?'
            : 'Turn on morning and evening adhkar reminders?'),
        content: Text(lang == 'bn'
            ? 'প্রতিদিন সকালে ও সন্ধ্যায় মাসনুন যিকির ও দোয়া পড়ার কথা Noor আপনাকে মনে করিয়ে দেবে।'
            : 'Noor can remind you to read the morning and evening adhkar every day.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(lang == 'bn' ? 'এখন নয়' : 'Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(lang == 'bn' ? 'চালু করুন' : 'Turn on'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _promptVisible = false;
    if (agreed == true) {
      final granted = await NoorNotificationService.instance.requestPermission();
      if (!mounted) return;
      if (granted) {
        await prefs.setBool('notifications_adhkar_enabled', true);
        await prefs.setBool(_adhkarAcceptedKey, true);
        await prefs.remove(_adhkarNextPromptKey);
        ref.read(notificationSettingsRevisionProvider.notifier).state++;
        await NoorNotificationService.instance.syncFromPreferences(prefs);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(lang == 'bn'
              ? 'সকাল-সন্ধ্যার আমলের রিমাইন্ডার চালু হয়েছে।'
              : 'Morning and evening reminders are enabled.'),
        ));
      } else {
        await _scheduleAdhkarPromptAgain(prefs);
      }
    } else {
      await _scheduleAdhkarPromptAgain(prefs);
    }
  }

  Future<void> _scheduleAdhkarPromptAgain(SharedPreferences prefs) async {
    final next = DateTime.now().add(_repeatDelay);
    await prefs.setInt(_adhkarNextPromptKey, next.millisecondsSinceEpoch);
    _adhkarPromptTimer?.cancel();
    _adhkarPromptTimer = Timer(_repeatDelay, () {
      if (mounted) _showAdhkarNotificationPrompt();
    });
    _schedulePrayerNotificationPrompt();
  }

  Future<void> _scheduleNextPrompt(SharedPreferences prefs) async {
    final next = DateTime.now().add(_repeatDelay);
    await prefs.setInt(_nextPromptKey, next.millisecondsSinceEpoch);
    _schedulePrayerNotificationPromptAt(next);
  }

  void _schedulePrayerNotificationPromptAt(DateTime due) {
    _prayerPromptTimer?.cancel();
    final delay = due.difference(DateTime.now());
    _prayerPromptTimer = Timer(
      delay.isNegative ? Duration.zero : delay,
      () {
        if (mounted) _showPrayerNotificationPrompt();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
