import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _required = ['reference', 'source', 'verified_by', 'verified_date'];

void main() {
  for (final file in ['hadith', 'dua', 'allah_names']) {
    test('$file.json: verified records are complete and IDs are unique', () {
      final list =
          jsonDecode(File('assets/data/$file.json').readAsStringSync()) as List;
      final ids = <String>{};
      final orders = <int>{};

      for (final raw in list.cast<Map<String, dynamic>>()) {
        final record = raw;
        expect(
          ids.add(record['id'] as String),
          isTrue,
          reason: 'duplicate id ${record['id']}',
        );

        if (record.containsKey('order')) {
          expect(
            orders.add(record['order'] as int),
            isTrue,
            reason: 'duplicate order ${record['order']} in $file.json',
          );
        }

        if (record['verified'] == true) {
          for (final key in _required) {
            expect(
              (record[key] ?? '').toString().trim().isNotEmpty,
              isTrue,
              reason: '${record['id']}: "$key" is empty',
            );
          }
        }

        if (file == 'hadith' && record['verified'] == true) {
          if ((record['id'] as String).startsWith('nawawi-')) {
            expect(
              (record['verified_by'] as String).contains('https://sunnah.com/nawawi40'),
              isTrue,
              reason: '${record['id']}: direct Hadith source link is missing',
            );
          }
          for (final key in [
            'category',
            'category_en',
            'arabic_text',
            'bangla_translation',
            'english_translation',
            'narrator',
            'grade',
          ]) {
            expect(
              (record[key] ?? '').toString().trim().isNotEmpty,
              isTrue,
              reason: '${record['id']}: "$key" is empty',
            );
          }
          expect(record['daily_eligible'], isA<bool>());
        }

        if (file == 'dua' && record['verified'] == true) {
          if ((record['id'] as String).startsWith('quran-') &&
              record['verified_date'] == '2026-11-21') {
            expect(
              (record['verified_by'] as String).contains('https://quran.com/'),
              isTrue,
              reason: '${record['id']}: direct Quran source link is missing',
            );
            expect(
              (record['translation_source'] ?? '').toString().trim(),
              isNotEmpty,
              reason: '${record['id']}: translation source note is missing',
            );
            expect(
              (record['license_note'] ?? '').toString().trim(),
              isNotEmpty,
              reason: '${record['id']}: translation note is missing',
            );
          }
          for (final key in [
            'category_bn',
            'category_en',
            'arabic_text',
            'bangla_translation',
            'english_translation',
          ]) {
            expect(
              (record[key] ?? '').toString().trim().isNotEmpty,
              isTrue,
              reason: '${record['id']}: "$key" is empty',
            );
          }
        }
      }
    });
  }

  test('Allah names asset contains 99 complete ordered entries', () {
    final names = jsonDecode(
      File('assets/data/allah_names.json').readAsStringSync(),
    ) as List;
    expect(names, hasLength(99));

    final orders = <int>{};
    final ids = <String>{};
    for (final raw in names.cast<Map<String, dynamic>>()) {
      expect(ids.add(raw['id'] as String), isTrue);
      final order = raw['order'] as int;
      expect(orders.add(order), isTrue);
      expect(order, inInclusiveRange(1, 99));
      for (final key in [
        'arabic',
        'transliteration',
        'bangla',
        'english',
      ]) {
        expect(
          (raw[key] ?? '').toString().trim(),
          isNotEmpty,
          reason: '${raw['id']}: "$key" is empty',
        );
      }
    }
    expect(orders, Set<int>.from(List<int>.generate(99, (i) => i + 1)));
  });

  test('expanded Hadith and Dua collections contain the new records', () {
    final hadith =
        jsonDecode(File('assets/data/hadith.json').readAsStringSync()) as List;
    final duas =
        jsonDecode(File('assets/data/dua.json').readAsStringSync()) as List;
    expect(hadith.length, 88);
    expect(duas.length, 81);
    expect(
      hadith.where((item) => (item['id'] as String).startsWith('nawawi-')).length,
      25,
    );
    final newHadith = hadith.where((item) =>
        item['collection_batch'] == 'expanded-50-hadith-2026-11-21').toList();
    expect(newHadith, hasLength(50));
    for (final item in newHadith) {
      expect(
        (item['verified_by'] as String).contains('https://sunnah.com/bukhari:'),
        isTrue,
        reason: '${item['id']}: direct Sahih al-Bukhari reference is missing',
      );
      expect(item['grade'], 'সহিহ');
      expect(item['daily_eligible'], isTrue);
    }
    final newDuas = duas.where((item) =>
        item['collection_batch'] == 'expanded-50-dua-2026-11-21').toList();
    expect(newDuas, hasLength(50));
    expect(
      newDuas.where((item) => (item['id'] as String).startsWith('quran-')).length,
      40,
    );
    expect(
      newDuas.where((item) => (item['id'] as String).startsWith('bukhari-dua-')).length,
      10,
    );
    for (final item in newDuas) {
      expect((item['verified_by'] as String).trim(), isNotEmpty);
      expect(item['verified_date'], '2026-11-21');
      expect((item['translation_source'] as String).trim(), isNotEmpty);
      expect((item['license_note'] as String).trim(), isNotEmpty);
    }
  });

  test('daily hadith collection contains multiple distinct entries', () {
    final list =
        jsonDecode(File('assets/data/hadith.json').readAsStringSync()) as List;
    final eligible = list
        .where((item) =>
            item['verified'] == true && item['daily_eligible'] == true)
        .toList();
    expect(eligible.length, greaterThan(1));
  });

  test('dua topic collection is not empty', () {
    final list =
        jsonDecode(File('assets/data/dua.json').readAsStringSync()) as List;
    expect(list, isNotEmpty);
  });
}
