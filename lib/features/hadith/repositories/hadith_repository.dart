import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/hadith.dart';

class HadithRepository {
  /// নিয়ম: শুধু verified=true কনটেন্ট UI-তে যাবে। এই ফিল্টার শুধু এখানেই থাকবে।
  Future<List<Hadith>> loadVerified() async {
    final raw = await rootBundle.loadString('assets/data/hadith.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => Hadith.fromJson(e as Map<String, dynamic>))
        .where((h) => h.verified)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return list;
  }
}
