import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/prefs.dart';

class SettingsState {
  final String lang; // 'bn' | 'en'
  final ThemeMode themeMode;
  final double fontScale;
  const SettingsState(
      {required this.lang, required this.themeMode, required this.fontScale});

  SettingsState copyWith({String? lang, ThemeMode? themeMode, double? fontScale}) =>
      SettingsState(
        lang: lang ?? this.lang,
        themeMode: themeMode ?? this.themeMode,
        fontScale: fontScale ?? this.fontScale,
      );
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final p = ref.read(sharedPrefsProvider);

    // পুরোনো বা নষ্ট preference থাকলেও অ্যাপ যেন crash না করে।
    final savedLang = p.getString('lang');
    final lang = savedLang == 'en' ? 'en' : 'bn';
    final savedThemeIndex = p.getInt('theme') ?? ThemeMode.system.index;
    final safeThemeIndex = savedThemeIndex.clamp(0, ThemeMode.values.length - 1);
    final savedFontScale = p.getDouble('font_scale') ?? 1.0;
    final fontScale = savedFontScale.isFinite
        ? savedFontScale.clamp(0.85, 1.4).toDouble()
        : 1.0;

    return SettingsState(
      lang: lang,
      themeMode: ThemeMode.values[safeThemeIndex],
      fontScale: fontScale,
    );
  }

  void setLang(String lang) {
    final safeLang = lang == 'en' ? 'en' : 'bn';
    ref.read(sharedPrefsProvider).setString('lang', safeLang);
    state = state.copyWith(lang: safeLang);
  }

  void setThemeMode(ThemeMode m) {
    ref.read(sharedPrefsProvider).setInt('theme', m.index);
    state = state.copyWith(themeMode: m);
  }

  void setFontScale(double v) {
    final safeValue = v.isFinite ? v.clamp(0.85, 1.4).toDouble() : 1.0;
    ref.read(sharedPrefsProvider).setDouble('font_scale', safeValue);
    state = state.copyWith(fontScale: safeValue);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
