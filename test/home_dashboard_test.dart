import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bangla_utilities/bangla_utilities.dart';
import 'package:hijri_date_time/hijri_date_time.dart';
import 'package:islamic_app/core/time/bangladesh_clock.dart';
import 'package:islamic_app/core/theme/app_theme.dart';
import 'package:islamic_app/core/theme/app_colors.dart';
import 'package:islamic_app/core/localization/bn_digits.dart';
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
  ThemeMode themeMode = ThemeMode.light,
  Map<String, Object> initialPreferences = const {},
}) async {
  SharedPreferences.setMockInitialValues(initialPreferences);
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
          HomeCity(
            id: 'tangail',
            nameBn: 'টাঙ্গাইল',
            nameEn: 'Tangail',
            lat: 24.2513,
            lng: 89.9167,
          ),
        ],
      ),
      hadithListProvider.overrideWith((ref) => <Hadith>[]),
      verifiedDuasProvider.overrideWith(
        (ref) => <Map<String, dynamic>>[],
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const MainShell(),
    ),
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
  for (final themeMode in [
    ThemeMode.light,
    ThemeMode.system,
    ThemeMode.dark,
  ]) {
    testWidgets(
      'Home location dropdown remains readable in ${themeMode.name} theme',
      (tester) async {
        if (themeMode == ThemeMode.system) {
          tester.binding.platformDispatcher.platformBrightnessTestValue =
              Brightness.light;
          addTearDown(
            tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
          );
        }

        await _pumpMainShell(tester, themeMode: themeMode);

        final dropdownFinder =
            find.byKey(const Key('home_location_dropdown'));
        final dropdown =
            tester.widget<PopupMenuButton<String>>(dropdownFinder);
        final scheme = Theme.of(tester.element(dropdownFinder)).colorScheme;

        expect(dropdown.color, scheme.surface);
        expect(dropdown.surfaceTintColor, Colors.transparent);
        expect(
          tester.widget<Text>(
            find.byKey(const Key('home_location_name')),
          ).style?.color,
          AppColors.primaryText,
        );
        final locationDecoration =
            tester.widget<Container>(find.byKey(const Key('home_location_chip')));
        expect(
          (locationDecoration.decoration as BoxDecoration).color,
          AppColors.activeSurface,
        );
        expect(
          tester.getSize(find.byKey(const Key('home_location_chip'))).width,
          lessThan(180),
        );
        for (final chipKey in [
          'home_sunrise_chip',
          'home_sunset_chip',
        ]) {
          expect(
            tester.getSize(find.byKey(Key(chipKey))).width,
            lessThan(150),
          );
        }
        expect(
          find.descendant(
            of: find.byKey(const Key('home_sunrise_chip')),
            matching: find.byIcon(Icons.wb_sunny),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('home_sunset_chip')),
            matching: find.byIcon(Icons.wb_twilight),
          ),
          findsOneWidget,
        );

        await tester.tap(dropdownFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        final districtOption = tester.widget<Text>(find.text('টাঙ্গাইল'));
        expect(districtOption.style?.color, scheme.onSurface);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Home daily Amal tracker reads saved progress and opens its checklist', (tester) async {
    final today = bangladeshCalendarDate(DateTime.now());
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await _pumpMainShell(
      tester,
      clock: DateTime.now,
      initialPreferences: {
        'daily_amal_$dateKey': ['quran', 'morning'],
      },
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('home_daily_amal_tracker_card')),
      240,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('দৈনিক আমল'), findsOneWidget);
    expect(find.text('২ / ৬ সম্পন্ন'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('home_daily_amal_tracker_card'))).width,
      greaterThan(0),
    );

    await tester.tap(find.byKey(const Key('home_daily_amal_tracker_card')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('আজকের আমলের তালিকা'), findsOneWidget);
    expect(find.text('2 / 6 আমল সম্পন্ন'), findsOneWidget);
  });

  testWidgets('Home dashboard displays the redesigned prayer header and features', (tester) async {
    await _pumpMainShell(tester);

    expect(find.text('বাংলা'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);
    expect(find.text('নামাজের সময়সূচি'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));

    await tester.scrollUntilVisible(
      find.byKey(const Key('home_prayer_tracker_card')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('আজকের ট্র্যাকার'), findsOneWidget);
    expect(find.text('নামাজ ট্র্যাকার'), findsOneWidget);
    expect(find.text('দৈনিক আমল'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('টপ ফিচার'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('টপ ফিচার'), findsOneWidget);
    expect(find.text('কিবলা'), findsNothing);

    // Top feature items keep their three-column arrangement without tracker tiles.
    final namesCenter = tester.getCenter(find.text('আল্লাহর ৯৯ নাম'));
    final firstRowY = namesCenter.dy;
    expect(tester.getCenter(find.text('ছোট সূরা')).dy, closeTo(firstRowY, 1));
    expect(tester.getCenter(find.text('হাদিস').first).dy, closeTo(firstRowY, 1));
    final secondRowY = tester.getCenter(find.text('রুকইয়াহ')).dy;
    expect(secondRowY, greaterThan(firstRowY + 40));
    expect(tester.getCenter(find.text('তাসবিহ')).dy, closeTo(secondRowY, 1));
    expect(tester.getCenter(find.text('সকাল-সন্ধ্যা')).dy, closeTo(secondRowY, 1));
    final thirdRowY = tester.getCenter(find.text('দৈনন্দিন ব্যবহার')).dy;
    expect(thirdRowY, greaterThan(secondRowY + 40));
  });


  testWidgets('Home shows all three full dates for the Bangladesh calendar day', (tester) async {
    // 18:30 UTC is already 00:30 on the following day in Bangladesh.
    final instant = DateTime.utc(2026, 11, 21, 18, 30);
    await _pumpMainShell(tester, clock: () => instant);

    expect(
      tester.widget<Text>(find.byKey(const Key('home_gregorian_date'))).data,
      'রবিবার, ২২ নভেম্বর ২০২৬',
    );

    final date = DateTime(2026, 11, 22);
    final bangla = BanglaDate.fromDateTime(date);
    expect(
      tester.widget<Text>(find.byKey(const Key('home_bangla_date'))).data,
      'রবিবার, ${localizeDigits(bangla.dayInt, 'bn')} ${bangla.monthName} ${localizeDigits(bangla.yearInt, 'bn')}',
    );

    final hijri = HijriDateTime.fromGregorian(date);
    const hijriMonthsAr = [
      'مُحَرَّم', 'صَفَر', 'رَبِيعُ الأَوَّل', 'رَبِيعُ الآخِر',
      'جُمَادَى الأُولَى', 'جُمَادَى الآخِرَة', 'رَجَب', 'شَعْبَان',
      'رَمَضَان', 'شَوَّال', 'ذُو القَعْدَة', 'ذُو الحِجَّة',
    ];
    expect(
      tester.widget<Text>(find.byKey(const Key('home_hijri_date'))).data,
      '${hijri.day} ${hijriMonthsAr[hijri.month - 1]} ${hijri.year} هـ',
    );
    await tester.tap(find.text('EN'));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('home_hijri_date'))).data,
      '${hijri.day} ${hijriMonthsAr[hijri.month - 1]} ${hijri.year} هـ',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('home_gregorian_date'))).data,
      '22 November 2026',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('home_bangla_date'))).data,
      'Sunday, ${bangla.dayInt} ${[
        'Boishakh', 'Joishtho', 'Asharh', 'Shrabon', 'Bhadro', 'Ashwin',
        'Kartik', 'Ogrohayon', 'Poush', 'Magh', 'Falgun', 'Choitro',
      ][bangla.monthInt - 1]} ${bangla.yearInt}',
    );

  });

  testWidgets('Home keeps all three full date labels visible on narrow screens', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final instant = DateTime.utc(2026, 11, 21, 18, 30);
    await _pumpMainShell(tester, clock: () => instant);

    for (final key in [
      'home_hijri_date',
      'home_gregorian_date',
      'home_bangla_date',
    ]) {
      final dateText = tester.widget<Text>(find.byKey(Key(key)));
      expect(dateText.maxLines, isNull, reason: '$key must not truncate the date');
      expect(dateText.overflow, isNull, reason: '$key must wrap instead of using ellipsis');
      expect(dateText.data, isNotEmpty);
    }
    final layoutException = tester.takeException();
    if (layoutException != null) {
      debugPrint(layoutException.toString());
      debugDumpRenderTree();
    }
    expect(layoutException, isNull);
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
    expect(tester.getSize(header).height, lessThan(300));

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
    expect(find.text('দৈনন্দিন ব্যবহার'), findsNothing);

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

    final now = bangladeshWallClock(DateTime.now());
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

    final now = bangladeshWallClock(DateTime.now());
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
