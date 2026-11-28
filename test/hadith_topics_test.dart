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
    expect(find.text('198টি হাদিস'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ChoiceChip),
        matching: find.text('আদব ও চরিত্র'),
      ),
      findsOneWidget,
    );

    // Render the Dua collection in its own tab instead of relying on a
    // lazy ListView child that may be outside the current viewport.
    await pumpScreen(tester, HadithDuaSection.dua);
    expect(find.text('দোয়ার বিষয়সমূহ'), findsOneWidget);
    expect(find.text('104টি দোয়া'), findsOneWidget);
    expect(find.text('সকাল-সন্ধ্যা'), findsOneWidget);
    expect(find.text('হিদায়াত ও ঈমান'), findsOneWidget);
    final firstTopicFolder = find.byType(ListTile).first;
    await tester.ensureVisible(firstTopicFolder);
    await tester.tap(firstTopicFolder);
    await tester.pump();
    expect(find.text('সব বিষয়'), findsOneWidget);
  });

  testWidgets('Hadith tab contains no Dua section', (tester) async {
    await pumpScreen(tester, HadithDuaSection.hadith);

    expect(find.text('হাদিসের বিষয়সমূহ'), findsOneWidget);
    expect(find.text('198টি হাদিস'), findsOneWidget);
    expect(find.text('দোয়ার বিষয়সমূহ'), findsNothing);
  });

  testWidgets('Dua tab contains no Hadith section', (tester) async {
    await pumpScreen(tester, HadithDuaSection.dua);

    expect(find.text('দোয়ার বিষয়সমূহ'), findsOneWidget);
    expect(find.text('104টি দোয়া'), findsOneWidget);
    expect(find.text('হাদিসের বিষয়সমূহ'), findsNothing);
  });

  testWidgets('Morning and evening dua section filters the correct records', (tester) async {
    await pumpScreen(tester, HadithDuaSection.morningEveningDua);
    expect(find.text('সকাল-সন্ধ্যার দোয়া'), findsOneWidget);
    expect(find.text('সকাল-সন্ধ্যা'), findsOneWidget);
    expect(find.text('16টি দোয়া'), findsOneWidget);
    expect(find.text('84টি দোয়া'), findsNothing);
  });

  testWidgets('Daily dua section shows only relevant topic folders', (tester) async {
    await pumpScreen(tester, HadithDuaSection.dailyDua);
    expect(find.text('দৈনন্দিন ব্যবহার'), findsOneWidget);
    expect(find.text('দোয়ার বিষয়সমূহ'), findsOneWidget);
    expect(find.text('রিজিক ও কল্যাণ'), findsOneWidget);
    expect(find.text('হিদায়াত ও ঈমান'), findsOneWidget);
    expect(find.text('সকাল-সন্ধ্যা'), findsNothing);
    final firstTopicFolder = find.byType(ListTile).first;
    await tester.tap(firstTopicFolder);
    await tester.pump();
    expect(find.text('সব বিষয়'), findsOneWidget);
  });
}
