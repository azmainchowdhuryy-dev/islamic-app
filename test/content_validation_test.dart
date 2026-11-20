import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// verified=true রেকর্ডে এই ফিল্ডগুলো ফাঁকা থাকলে টেস্ট ব্যর্থ হবে।
const _required = ['reference', 'source', 'verified_by', 'verified_date'];

void main() {
  for (final file in ['hadith', 'dua', 'allah_names']) {
    test('$file.json: verified records are complete & ids unique', () {
      final list = jsonDecode(File('assets/data/$file.json').readAsStringSync()) as List;
      final ids = <String>{};
      for (final r in list.cast<Map<String, dynamic>>()) {
        expect(ids.add(r['id'] as String), isTrue, reason: 'duplicate id ${r['id']}');
        if (r['verified'] == true) {
          for (final k in _required) {
            expect((r[k] ?? '').toString().trim().isNotEmpty, isTrue,
                reason: '${r['id']}: "$k" is empty');
          }
        }
      }
    });
  }
}
