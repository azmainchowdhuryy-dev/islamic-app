import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/features/quran/screens/short_surahs_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the 16 selected surahs in the requested order', () async {
    final surahs = await loadShortSurahs();

    expect(surahs, hasLength(16));
    expect(surahs.first.number, 1);
    expect(surahs.first.nameBn, 'আল-ফাতিহা');
    expect(surahs.first.ayahCount, 7);
    expect(surahs.first.verses, hasLength(7));
    expect(
      surahs.map((surah) => surah.number).toList(),
      [1, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114],
    );
    expect(
      surahs.map((surah) => surah.ayahCount).toList(),
      [7, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6],
    );
    expect(surahs.last.number, 114);
  });

  test('every selected surah has sequential Arabic and Bengali verses', () async {
    final surahs = await loadShortSurahs();

    for (final surah in surahs) {
      expect(surah.verses, hasLength(surah.ayahCount));
      for (var i = 0; i < surah.verses.length; i++) {
        final verse = surah.verses[i];
        expect(verse.number, i + 1);
        expect(verse.arabic.trim(), isNotEmpty);
        expect(verse.translation.trim(), isNotEmpty);
      }
    }
  });
  test('content source metadata records the exact publishers and editions', () async {
    final raw = await rootBundle.loadString('assets/data/short_surahs.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final arabic = data['arabic_source'] as Map<String, dynamic>;
    final translation = data['translation'] as Map<String, dynamic>;

    expect(arabic['title'], 'Tanzil Quran Text (Uthmani, Version 1.1)');
    expect(arabic['copyright'], 'Copyright (C) 2007-2021 Tanzil Project');
    expect(arabic['license'], 'Creative Commons Attribution 3.0');
    expect(arabic['source_url'], 'https://tanzil.net');
    expect(translation['source'], 'QuranEnc.com');
    expect(translation['title'], contains('যাকারিয়া'));
    expect(translation['key'], 'bengali_zakaria');
    expect(translation['version'], '1.1.1');
    expect(
      translation['source_url'],
      'https://quranenc.com/bn/browse/bengali_zakaria',
    );
  });

  test('translation notes render bold markup without exposing HTML tags', () {
    const note = '<b>শিরোনাম:</b> ব্যাখ্যার মূল অংশ।';
    final spans = buildTranslationNoteSpans(note, const TextStyle(fontSize: 14));
    final rendered = TextSpan(children: spans);

    expect(rendered.toPlainText(), 'শিরোনাম: ব্যাখ্যার মূল অংশ।');
    expect(spans.first.style?.fontWeight, FontWeight.bold);
    expect(spans.last.style?.fontWeight, isNull);
  });

}
