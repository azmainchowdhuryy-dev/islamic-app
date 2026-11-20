import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/providers/settings_provider.dart';
import 'bn_digits.dart';

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
    // ---- তাসবিহ ----
    'durood': 'দরুদ শরিফ',
    'istighfar': 'ইস্তিগফার',
    'session_count': 'বর্তমান গণনা',
    'total_count': 'মোট গণনা',
    'target': 'লক্ষ্য',
    'select_target': 'লক্ষ্য নির্বাচন করুন',
    'tap_to_count': 'গুনতে বৃত্তে ট্যাপ করুন',
    'target_completed': 'আলহামদুলিল্লাহ! লক্ষ্য পূর্ণ হয়েছে',
    'target_done_label': 'লক্ষ্য পূর্ণ হয়েছে',
    'reset': 'রিসেট',
    'reset_title': 'রিসেট করবেন?',
    'reset_body': 'বর্তমান গণনা শূন্য হবে। মোট গণনা মুছবে না।',
    'cancel': 'বাতিল',
    'vibration': 'ভাইব্রেশন',
    'sound': 'শব্দ',
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
    // ---- Tasbih ----
    'durood': 'Durood Sharif',
    'istighfar': 'Istighfar',
    'session_count': 'Session count',
    'total_count': 'Lifetime total',
    'target': 'Target',
    'select_target': 'Select target',
    'tap_to_count': 'Tap the circle to count',
    'target_completed': 'Alhamdulillah! Target completed',
    'target_done_label': 'Target completed',
    'reset': 'Reset',
    'reset_title': 'Reset counter?',
    'reset_body': 'The session count will be set to zero. Your lifetime total will not be deleted.',
    'cancel': 'Cancel',
    'vibration': 'Vibration',
    'sound': 'Sound',
  },
};

class AppStrings {
  final String lang;
  const AppStrings(this.lang);

  String t(String key) => _t[lang]?[key] ?? _t['en']![key] ?? key;

  /// সংখ্যা ভাষা অনুযায়ী: বাংলা হলে বাংলা অঙ্ক, ইংরেজি হলে ইংরেজি।
  String digits(Object value) => localizeDigits(value, lang);
}

final stringsProvider =
    Provider<AppStrings>((ref) => AppStrings(ref.watch(settingsProvider).lang));
