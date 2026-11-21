import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/services/prefs.dart';
import 'package:islamic_app/features/settings/screens/ibadah_tools_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _nameSubtitleFinder() => find.byWidgetPredicate(
      (widget) => widget is Text && (widget.data ?? '').contains(' • '),
      description: 'Allah name subtitles',
    );

Future<SharedPreferences> _prefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

Future<void> _pumpSection(
  WidgetTester tester,
  SharedPreferences prefs,
  IbadahToolsSection section,
) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: MaterialApp(home: IbadahToolsScreen(section: section)),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('combined ibadah screen retains all existing sections', (tester) async {
    final prefs = await _prefs();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: IbadahToolsScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('পাঁচ ওয়াক্ত নামাজের হিসাব'), findsOneWidget);
    expect(find.text('ফজর'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('আল্লাহর সুন্দর নামসমূহ'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('আল্লাহর সুন্দর নামসমূহ'), findsOneWidget);
    expect(_nameSubtitleFinder(), findsNWidgets(99));
  });

  testWidgets('malformed saved tracker and favorite values are ignored', (tester) async {
    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    SharedPreferences.setMockInitialValues({
      'prayer_tracker_$dateKey': ['fajr', 'not-a-prayer'],
      'daily_amal_$dateKey': ['quran', 'not-an-amal'],
      'asma_favorites': ['2', 'not-a-number', '0', '100'],
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: IbadahToolsScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('1 / 5 ওয়াক্ত আদায় হয়েছে'), findsOneWidget);
    expect(find.text('1 / 6 আমল সম্পন্ন'), findsOneWidget);
  });

  testWidgets('name search filters the list', (tester) async {
    final prefs = await _prefs();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: IbadahToolsScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byType(TextField),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Ar-Rahman');
    await tester.pumpAndSettle();

    expect(find.text('Ar-Rahman • পরম করুণাময়'), findsOneWidget);
    expect(_nameSubtitleFinder(), findsOneWidget);
  });

  testWidgets('prayer tracker screen shows only prayer tracking', (tester) async {
    final prefs = await _prefs();
    await _pumpSection(tester, prefs, IbadahToolsSection.prayers);

    expect(find.text('আজকের নামাজ'), findsOneWidget);
    expect(find.text('পাঁচ ওয়াক্ত নামাজের হিসাব'), findsOneWidget);
    expect(find.text('দৈনিক আমল'), findsNothing);
    expect(find.text('আল্লাহর সুন্দর নামসমূহ'), findsNothing);
    expect(_nameSubtitleFinder(), findsNothing);
  });

  testWidgets('daily amal screen shows only its own checklist', (tester) async {
    final prefs = await _prefs();
    await _pumpSection(tester, prefs, IbadahToolsSection.dailyAmal);

    expect(find.text('দৈনিক আমল'), findsNWidgets(2));
    expect(find.text('পাঁচ ওয়াক্ত নামাজের হিসাব'), findsNothing);
    expect(find.text('আল্লাহর সুন্দর নামসমূহ'), findsNothing);
    expect(_nameSubtitleFinder(), findsNothing);
  });

  testWidgets('Allah names screen does not show tracker sections', (tester) async {
    final prefs = await _prefs();
    await _pumpSection(tester, prefs, IbadahToolsSection.names);

    expect(find.text('আল্লাহর ৯৯ নাম'), findsOneWidget);
    expect(find.text('আল্লাহর সুন্দর নামসমূহ'), findsOneWidget);
    expect(find.text('পাঁচ ওয়াক্ত নামাজের হিসাব'), findsNothing);
    expect(find.text('দৈনিক আমল'), findsNothing);
    expect(_nameSubtitleFinder(), findsNWidgets(99));
  });
}
