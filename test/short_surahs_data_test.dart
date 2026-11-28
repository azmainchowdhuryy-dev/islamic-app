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
