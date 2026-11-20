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
    return SettingsState(
      lang: p.getString('lang') ?? 'bn',
      themeMode: ThemeMode.values[p.getInt('theme') ?? 0],
      fontScale: p.getDouble('font_scale') ?? 1.0,
    );
  }

  void setLang(String lang) {
    ref.read(sharedPrefsProvider).setString('lang', lang);
    state = state.copyWith(lang: lang);
  }

  void setThemeMode(ThemeMode m) {
    ref.read(sharedPrefsProvider).setInt('theme', m.index);
    state = state.copyWith(themeMode: m);
  }

  void setFontScale(double v) {
    ref.read(sharedPrefsProvider).setDouble('font_scale', v);
    state = state.copyWith(fontScale: v);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
