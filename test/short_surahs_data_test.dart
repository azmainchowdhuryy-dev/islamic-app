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
}
