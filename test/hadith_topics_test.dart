import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/services/prefs.dart';
import 'package:islamic_app/features/hadith/models/hadith.dart';
import 'package:islamic_app/features/hadith/providers/hadith_provider.dart';
import 'package:islamic_app/features/hadith/screens/hadith_dua_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

late List<Hadith> _hadithFixture;
late List<Map<String, dynamic>> _duaFixture;

void main() {
  setUpAll(() {
    _hadithFixture = (jsonDecode(
      File('assets/data/hadith.json').readAsStringSync(),
    ) as List)
        .map((item) => Hadith.fromJson(item as Map<String, dynamic>))
        .where((item) => item.verified)
        .toList();

    _duaFixture = (jsonDecode(
      File('assets/data/dua.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>()
        .where((item) => item['verified'] == true)
        .toList();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    HadithDuaSection section,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        hadithListProvider.overrideWith((ref) => _hadithFixture),
        verifiedDuasProvider.overrideWith((ref) => _duaFixture),
      ],
      child: MaterialApp(home: HadithDuaScreen(section: section)),
    ));
    // Both providers are overridden with fixtures, so two bounded frames
    // are enough to render their data without waiting for an animation to settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('Combined Hadith and Dua view keeps both collections', (tester) async {
    await pumpScreen(tester, HadithDuaSection.all);

    expect(find.text('হাদিসের বিষয়সমূহ'), findsOneWidget);
    expect(find.text('88টি হাদিস'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ChoiceChip),
        matching: find.text('আদব ও চরিত্র'),
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('দোয়ার বিষয়সমূহ'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('দোয়ার বিষয়সমূহ'), findsOneWidget);
    expect(find.text('81টি দোয়া'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ChoiceChip),
        matching: find.text('পরিবার ও সন্তান'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Hadith tab contains no Dua section', (tester) async {
    await pumpScreen(tester, HadithDuaSection.hadith);

    expect(find.text('হাদিসের বিষয়সমূহ'), findsOneWidget);
    expect(find.text('88টি হাদিস'), findsOneWidget);
    expect(find.text('দোয়ার বিষয়সমূহ'), findsNothing);
  });

  testWidgets('Dua tab contains no Hadith section', (tester) async {
    await pumpScreen(tester, HadithDuaSection.dua);

    expect(find.text('দোয়ার বিষয়সমূহ'), findsOneWidget);
    expect(find.text('81টি দোয়া'), findsOneWidget);
    expect(find.text('হাদিসের বিষয়সমূহ'), findsNothing);
  });
}
