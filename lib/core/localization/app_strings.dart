import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/providers/settings_provider.dart';

/// নতুন লেখা যোগ করতে এখানে bn ও en দুই জায়গাতেই একই key বসান।
const Map<String, Map<String, String>> _t = {
  'bn': {
    'greeting': 'আসসালামু আলাইকুম',
    'home': 'হোম',
    'hadith_dua': 'হাদিস ও দোয়া',
    'tasbih': 'তাসবিহ',
    'more': 'আরও',
    'next_prayer': 'পরবর্তী ওয়াক্ত',
    'daily_hadith': 'আজকের হাদিস',
    'todays_prayers': 'আজকের পাঁচ ওয়াক্ত নামাজ',
    'settings': 'সেটিংস',
    'language': 'ভাষা',
    'theme': 'থিম',
    'theme_system': 'সিস্টেম',
    'theme_light': 'লাইট',
    'theme_dark': 'ডার্ক',
    'font_size': 'ফন্টের আকার',
    'coming_soon': 'শীঘ্রই আসছে',
  },
  'en': {
    'greeting': 'Assalamu Alaikum',
    'home': 'Home',
    'hadith_dua': 'Hadis & Dua',
    'tasbih': 'Tasbih',
    'more': 'More',
    'next_prayer': 'Next prayer',
    'daily_hadith': 'Daily Hadis',
    'todays_prayers': "Today's five prayers",
    'settings': 'Settings',
    'language': 'Language',
    'theme': 'Theme',
    'theme_system': 'System',
    'theme_light': 'Light',
    'theme_dark': 'Dark',
    'font_size': 'Font size',
    'coming_soon': 'Coming soon',
  },
};

class AppStrings {
  final String lang;
  const AppStrings(this.lang);
  String t(String key) => _t[lang]?[key] ?? _t['en']![key] ?? key;
}

final stringsProvider =
    Provider<AppStrings>((ref) => AppStrings(ref.watch(settingsProvider).lang));
