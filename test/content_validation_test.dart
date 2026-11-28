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
    expect(hadith.length, 200);
    expect(duas.length, 200);
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
    final newHadith100 = hadith.where((item) =>
        item['collection_batch'] == 'expanded-200-total-hadith-2026-11-28').toList();
    expect(newHadith100, hasLength(100));
    expect(newHadith100.every((item) => item['grade'] == 'সহিহ'), isTrue);
    expect(newHadith100.every((item) => item['verified'] == true), isTrue);
    expect(newHadith100.every((item) => (item['reference'] as String).isNotEmpty), isTrue);
    expect(newHadith100.every((item) => (item['verified_by'] as String).contains('https://sunnah.com/bukhari:')), isTrue);
    expect(newHadith100.every((item) => (item['bangla_translation'] as String).isNotEmpty), isTrue);
    final newHadith12 = hadith.where((item) =>
        item['collection_batch'] == 'expanded-100-total-hadith-2026-11-28').toList();
    expect(newHadith12, hasLength(12));
    for (final item in newHadith12) {
      expect(item['grade'], 'সহিহ');
      expect(item['verified'], isTrue);
      expect((item['verified_by'] as String).contains('https://sunnah.com/bukhari:'), isTrue);
      expect((item['bangla_translation'] as String).contains(RegExp(r'[\u0980-\u09FF]')), isTrue);
    }
    final newDua19 = duas.where((item) =>
        item['collection_batch'] == 'dua-100-total-2026-11-28').toList();
    expect(newDua19, hasLength(19));
    expect(newDua19.where((item) => item['usage_category'] == 'morning_evening').length, 10);
    expect(newDua19.where((item) => item['usage_category'] == 'daily').length, 9);
    expect(duas.where((item) => item['usage_category'] == 'morning_evening').length, 22);
    expect(duas.where((item) => item['usage_category'] == 'daily').length, 178);
    final newDua100 = duas.where((item) =>
        item['collection_batch'] == 'expanded-200-total-dua-2026-11-28').toList();
    expect(newDua100, hasLength(100));
    expect(newDua100.every((item) => item['verified'] == true), isTrue);
    expect(newDua100.every((item) => (item['reference'] as String).isNotEmpty), isTrue);
    expect(newDua100.every((item) => (item['transliteration_bn'] as String).isNotEmpty), isTrue);
    expect(newDua100.where((item) => item['usage_category'] == 'morning_evening').length, 10);
    for (final item in newDua19) {
      expect(item['verified'], isTrue);
      expect((item['arabic_text'] as String).trim(), isNotEmpty);
      expect((item['bangla_translation'] as String).trim(), isNotEmpty);
      expect((item['reference'] as String).trim(), isNotEmpty);
    }
  });

  test('Hadith and Dua folders are grouped into their verified topics', () {
    final hadith =
        jsonDecode(File('assets/data/hadith.json').readAsStringSync()) as List;
    final duas =
        jsonDecode(File('assets/data/dua.json').readAsStringSync()) as List;

    expect(
      hadith.map((item) => item['category']).toSet(),
      {
        'ঈমান ও আকিদা',
        'ইবাদত ও সালাত',
        'কুরআন ও জ্ঞান',
        'আদব ও চরিত্র',
        'পরিবার ও সমাজ',
        'যিকির ও দোয়া',
        'পবিত্রতা ও অজু',
        'হজ্জ ও উমরা',
      },
    );
    expect(
      duas.map((item) => item['category_bn']).toSet(),
      {
        'ক্ষমা ও তাওবা',
        'হিদায়াত ও ঈমান',
        'পরিবার ও সন্তান',
        'রিজিক ও কল্যাণ',
        'বিপদ ও নিরাপত্তা',
        'যিকির ও ইবাদত',
        'সকাল-সন্ধ্যা',
        'ঘুম ও জাগ্রত',
        'পবিত্রতা ও অজু',
        'সামাজিক শিষ্টাচার',
        'সালাত ও যিক্‌র',
        'আশ্রয় ও হেফাজত',
        'পিতামাতা ও পরিবার',
        'অসুস্থতা ও মৃত্যু',
        'প্রকৃতি ও আবহাওয়া',
        'খাদ্য ও পানীয়',
        'রমাদান ও সিয়াম',
        'সফর ও ভ্রমণ',
        'হজ্জ ও উমরা',
        'সম্পত্তি ও রিজিক',
        'শুকরিয়া ও তওবা',
        'মসজিদ',
      },
    );
  });

  test('new Arabic content has no accidental ellipsis truncation', () {
    final hadith =
        jsonDecode(File('assets/data/hadith.json').readAsStringSync()) as List;
    final duas =
        jsonDecode(File('assets/data/dua.json').readAsStringSync()) as List;

    for (final item in hadith.where((item) =>
        item['collection_batch'] == 'expanded-50-hadith-2026-11-21' ||
        item['collection_batch'] == 'expanded-200-total-hadith-2026-11-28')) {
      expect(
        (item['arabic_text'] as String).contains('...'),
        isFalse,
        reason: '${item['id']}: Arabic text has an unmarked omission',
      );
    }
    for (final item in duas.where((item) =>
        item['collection_batch'] == 'expanded-50-dua-2026-11-21')) {
      expect(
        (item['arabic_text'] as String).contains('...'),
        isFalse,
        reason: '${item['id']}: Arabic text has an unmarked omission',
      );
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
