import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/services/prefs.dart';
import 'package:islamic_app/features/hadith/models/hadith.dart';
import 'package:islamic_app/features/hadith/providers/hadith_provider.dart';
import 'package:islamic_app/features/hadith/screens/hadith_dua_screen.dart';
import 'package:islamic_app/features/home/screens/home_screen.dart';
import 'package:islamic_app/shared/widgets/main_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _pumpMainShell(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      homeCitiesProvider.overrideWith(
        (ref) => const [
          HomeCity(
            id: 'dhaka',
            nameBn: 'ঢাকা',
            nameEn: 'Dhaka',
            lat: 23.8103,
            lng: 90.4125,
          ),
        ],
      ),
      hadithListProvider.overrideWith((ref) => <Hadith>[]),
      verifiedDuasProvider.overrideWith(
        (ref) => <Map<String, dynamic>>[],
      ),
    ],
    child: const MaterialApp(home: MainShell()),
  ));

  // Home has a live countdown timer, so never use pumpAndSettle here.
  for (var i = 0;
      i < 20 && find.text('নামাজের সময়সূচি').evaluate().isEmpty;
      i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(find.text('নামাজের সময়সূচি'), findsOneWidget);
  return prefs;
}

void main() {
  test('Bangladesh city asset parses into valid unique city records', () {
    final raw = jsonDecode(
      File('assets/data/cities_bd.json').readAsStringSync(),
    ) as List;
    final cities = raw
        .map((item) => HomeCity.fromJson(item as Map<String, dynamic>))
        .toList();

    expect(cities, isNotEmpty);
    expect(cities.map((city) => city.id).toSet().length, cities.length);
    expect(cities.any((city) => city.id == 'dhaka'), isTrue);
    for (final city in cities) {
      expect(city.lat, inInclusiveRange(-90, 90));
      expect(city.lng, inInclusiveRange(-180, 180));
    }
  });
  testWidgets('Home dashboard displays the redesigned prayer header and features', (tester) async {
    await _pumpMainShell(tester);

    expect(find.text('বাংলা'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);
    expect(find.text('নামাজের সময়সূচি'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));

    await tester.scrollUntilVisible(
      find.text('টপ ফিচার'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('টপ ফিচার'), findsOneWidget);
    expect(find.text('ট্র্যাকার'), findsOneWidget);
    expect(find.text('কিবলা'), findsNothing);
    expect(find.text('দৈনিক আমল'), findsNothing);

    // The quick links must stay in exactly two rows, including on wide screens.
    final firstRowY = tester.getCenter(find.text('ট্র্যাকার')).dy;
    expect(tester.getCenter(find.text('হাদিস')).dy, closeTo(firstRowY, 1));
    expect(tester.getCenter(find.text('রুকইয়াহ')).dy, closeTo(firstRowY, 1));
    final secondRowY = tester.getCenter(find.text('৯৯ নাম')).dy;
    expect(secondRowY, greaterThan(firstRowY + 40));
    expect(tester.getCenter(find.text('তাসবিহ')).dy, closeTo(secondRowY, 1));
    expect(tester.getCenter(find.text('দোয়া')).dy, closeTo(secondRowY, 1));
  });

  testWidgets('Five bottom tabs open their matching sections', (tester) async {
    await _pumpMainShell(tester);

    await tester.tap(find.text('ফিচার'));
    await tester.pump();
    expect(find.text('সব ফিচার'), findsOneWidget);

    await tester.tap(find.text('হাদিস'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('হাদিসের বিষয়সমূহ'), findsOneWidget);
    expect(find.text('দোয়ার বিষয়সমূহ'), findsNothing);

    await tester.tap(find.text('দোয়া'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('দোয়ার বিষয়সমূহ'), findsOneWidget);
    expect(find.text('হাদিসের বিষয়সমূহ'), findsNothing);

    await tester.tap(find.text('আরও'));
    await tester.pump();
    expect(find.text('ফন্টের আকার'), findsOneWidget);

    await tester.tap(find.text('হোম'));
    await tester.pump();
    expect(find.text('নামাজের সময়সূচি'), findsOneWidget);
  });

  testWidgets('rapid prayer taps toggle from the latest optimistic state', (tester) async {
    final prefs = await _pumpMainShell(tester);

    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final prayerButton = find.byIcon(Icons.radio_button_unchecked).first;
    await tester.tap(prayerButton);
    await tester.tap(prayerButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));

    expect(
      prefs.getStringList('prayer_tracker_$dateKey') ?? [],
      isNot(contains('fajr')),
    );
  });

  testWidgets('Prayer status circle updates the daily saved tracker', (tester) async {
    final prefs = await _pumpMainShell(tester);

    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await tester.tap(find.byIcon(Icons.radio_button_unchecked).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(
      prefs.getStringList('prayer_tracker_$dateKey'),
      contains('fajr'),
    );

    await tester.tap(find.byIcon(Icons.check_circle).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(
      prefs.getStringList('prayer_tracker_$dateKey'),
      isNot(contains('fajr')),
    );
  });
}
