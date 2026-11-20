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
