import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bangla_utilities/bangla_utilities.dart';
import 'package:hijri_date_time/hijri_date_time.dart';
import 'package:islamic_app/core/time/bangladesh_clock.dart';
import 'package:islamic_app/core/services/prefs.dart';
import 'package:islamic_app/features/hadith/models/hadith.dart';
import 'package:islamic_app/features/hadith/providers/hadith_provider.dart';
import 'package:islamic_app/features/hadith/screens/hadith_dua_screen.dart';
import 'package:islamic_app/features/home/screens/home_screen.dart';
import 'package:islamic_app/shared/widgets/main_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _pumpMainShell(
  WidgetTester tester, {
  DateTime Function()? clock,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      appClockProvider.overrideWithValue(clock ?? DateTime.now),
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

    expect(cities, hasLength(64));
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

    // 99 Names of Allah sits directly to the right of Tracker.
    final trackerCenter = tester.getCenter(find.text('ট্র্যাকার'));
    final firstRowY = trackerCenter.dy;
    final namesCenter = tester.getCenter(find.text('আল্লাহর ৯৯ নাম'));
    expect(namesCenter.dy, closeTo(firstRowY, 3));
    expect(namesCenter.dx, greaterThan(trackerCenter.dx));
    expect(tester.getCenter(find.text('হাদিস').first).dy, closeTo(firstRowY, 1));
    final secondRowY = tester.getCenter(find.text('রুকইয়াহ')).dy;
    expect(secondRowY, greaterThan(firstRowY + 40));
    expect(tester.getCenter(find.text('তাসবিহ')).dy, closeTo(secondRowY, 1));
    expect(tester.getCenter(find.text('দোয়া').first).dy, closeTo(secondRowY, 1));
  });


  testWidgets('Home shows all three full dates for the Bangladesh calendar day', (tester) async {
    // 18:30 UTC is already 00:30 on the following day in Bangladesh.
    final instant = DateTime.utc(2026, 11, 21, 18, 30);
    await _pumpMainShell(tester, clock: () => instant);

    expect(
      tester.widget<Text>(find.byKey(const Key('home_gregorian_date'))).data,
      'ইংরেজি: ২২ নভেম্বর ২০২৬',
    );

    final date = DateTime.utc(2026, 11, 22);
    final bangla = BanglaDate.fromDateTime(date);
    expect(
      tester.widget<Text>(find.byKey(const Key('home_bangla_date'))).data,
      'বাংলা: ${bangla.dayInt} ${bangla.monthName} ${bangla.yearInt}'
          .replaceFirst('বাংলা:', 'বাংলা:'),
    );

    final hijri = HijriDateTime.fromGregorian(date);
    const hijriMonthsBn = [
      'মুহাররম', 'সফর', 'রবিউল আউয়াল', 'রবিউস সানি', 'জমাদিউল আউয়াল',
      'জমাদিউস সানি', 'রজব', 'শাবান', 'রমজান', 'শাওয়াল', 'জিলকদ', 'জিলহজ',
    ];
    expect(
      tester.widget<Text>(find.byKey(const Key('home_hijri_date'))).data,
      'হিজরি: রবি, ${hijri.day} ${hijriMonthsBn[hijri.month - 1]} ${hijri.year}',
    );
  });

  testWidgets('Home calendar icon opens the separate prayer calendar screen', (tester) async {
    await _pumpMainShell(tester);

    await tester.tap(find.byKey(const Key('home_open_prayer_calendar')));
    for (var i = 0;
        i < 30 && find.text('সালাতের সময়').evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('ক্যালেন্ডার').last, findsOneWidget);
    final calendarScroll = find.byKey(const Key('prayer_calendar_scroll_view'));
    expect(calendarScroll, findsOneWidget);

    for (final section in [
      'সালাতের সময়',
      'নফল সালাতের সময়',
      'সালাতের নিষিদ্ধ সময়',
      'সাওমের সময়সূচী',
      'সূর্যোদয় ও সূর্যাস্ত',
    ]) {
      await tester.scrollUntilVisible(
        find.text(section),
        260,
        scrollable: find.descendant(
          of: calendarScroll,
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text(section), findsOneWidget);
    }

    await tester.tap(find.byTooltip('ফিরে যান'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('নামাজের সময়সূচি'), findsOneWidget);
  });

  testWidgets('Home prayer countdown text sits inside the upper arch and panels are compact', (tester) async {
    await _pumpMainShell(tester);

    final header = find.byKey(const Key('home_header_panel'));
    final arc = find.byKey(const Key('next_prayer_arc'));
    expect(header, findsOneWidget);
    expect(arc, findsOneWidget);
    expect(tester.getSize(header).height, lessThan(250));

    final arcRect = tester.getRect(arc);
    final curveSize = tester.getSize(
      find.byKey(const Key('next_prayer_curve')),
    );
    expect(curveSize.width, lessThan(arcRect.width * 0.75));
    expect(curveSize.width, lessThanOrEqualTo(260));
    for (final key in [
      'next_prayer_name',
      'next_prayer_remaining_label',
      'next_prayer_countdown',
    ]) {
      final textRect = tester.getRect(find.byKey(Key(key)));
      expect(textRect.top, greaterThan(arcRect.top + 14), reason: '$key should be below the curve');
      expect(textRect.bottom, lessThan(arcRect.bottom), reason: '$key should remain inside the arch area');
    }

    expect(
      tester.widget<Text>(find.byKey(const Key('next_prayer_name'))).style?.fontSize,
      21,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('next_prayer_remaining_label'))).style?.fontSize,
      13,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('next_prayer_countdown'))).style?.fontSize,
      24,
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('home_prayer_times_card')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(
      tester.getSize(find.byKey(const Key('home_prayer_times_card'))).height,
      lessThan(275),
    );
  });

  testWidgets('Home prayer countdown slides to the second item every five seconds', (tester) async {
    await _pumpMainShell(tester);

    final countdownName = find.byKey(const Key('next_prayer_name'));
    final firstName = tester.widget<Text>(countdownName).data;

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 500));

    expect(countdownName, findsOneWidget);
    final secondName = tester.widget<Text>(countdownName).data;
    expect(secondName, isNot(firstName));
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

    final fajrButton = find.byKey(const Key('home_prayer_toggle_fajr'));
    expect(fajrButton, findsOneWidget);
    await tester.tap(fajrButton);
    await tester.pump();
    await tester.tap(fajrButton);
    await tester.pump();
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
