import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/services/prefs.dart';
import 'package:islamic_app/features/hadith/models/hadith.dart';
import 'package:islamic_app/features/hadith/providers/hadith_provider.dart';
import 'package:islamic_app/features/hadith/screens/hadith_dua_screen.dart';
import 'package:islamic_app/features/settings/screens/ibadah_tools_screen.dart';
import 'package:islamic_app/features/tools/screens/features_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _openFeature(
  WidgetTester tester,
  String label,
) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpFeatures(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        hadithListProvider.overrideWith((ref) => <Hadith>[]),
        verifiedDuasProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[],
        ),
      ],
      child: const MaterialApp(home: FeaturesScreen()),
    ));
    await tester.pump();
  }

  testWidgets('Features screen exposes the remaining supported tools', (tester) async {
    await pumpFeatures(tester);

    expect(find.text('সব ফিচার'), findsOneWidget);
    expect(find.text('আজকের নামাজ'), findsOneWidget);
    expect(find.text('দৈনিক আমল'), findsOneWidget);
    expect(find.text('কিবলা'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('রুকইয়াহ'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('রুকইয়াহ'), findsOneWidget);
    expect(find.text('কিবলা'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('তাসবিহ'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('আল্লাহর ৯৯ নাম'), findsOneWidget);
    expect(find.text('তাসবিহ'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('হাদিস ও দোয়া'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('হাদিস ও দোয়া'), findsOneWidget);
  });

  testWidgets('Prayer tracker feature opens only prayer section', (tester) async {
    await pumpFeatures(tester);
    await _openFeature(tester, 'আজকের নামাজ');

    final trackerScreen = find.byType(IbadahToolsScreen);
    expect(trackerScreen, findsOneWidget);
    expect(
      find.descendant(of: trackerScreen, matching: find.text('আজকের নামাজ')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: trackerScreen,
        matching: find.text('পাঁচ ওয়াক্ত নামাজের হিসাব'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: trackerScreen, matching: find.text('দৈনিক আমল')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: trackerScreen,
        matching: find.text('আল্লাহর সুন্দর নামসমূহ'),
      ),
      findsNothing,
    );
  });

  testWidgets('Daily Amal feature opens only its checklist', (tester) async {
    await pumpFeatures(tester);
    await _openFeature(tester, 'দৈনিক আমল');

    final amalScreen = find.byType(IbadahToolsScreen);
    expect(amalScreen, findsOneWidget);
    expect(
      find.descendant(of: amalScreen, matching: find.text('দৈনিক আমল')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: amalScreen,
        matching: find.text('আজকের আমলের তালিকা'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: amalScreen,
        matching: find.text('পাঁচ ওয়াক্ত নামাজের হিসাব'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: amalScreen,
        matching: find.text('আল্লাহর সুন্দর নামসমূহ'),
      ),
      findsNothing,
    );
  });

  testWidgets('Allah names feature opens only the 99 names list', (tester) async {
    await pumpFeatures(tester);
    await tester.scrollUntilVisible(
      find.text('আল্লাহর ৯৯ নাম'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await _openFeature(tester, 'আল্লাহর ৯৯ নাম');

    final namesScreen = find.byType(IbadahToolsScreen);
    expect(namesScreen, findsOneWidget);
    expect(
      find.descendant(
        of: namesScreen,
        matching: find.text('আল্লাহর সুন্দর নামসমূহ'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: namesScreen,
        matching: find.text('পাঁচ ওয়াক্ত নামাজের হিসাব'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(of: namesScreen, matching: find.text('দৈনিক আমল')),
      findsNothing,
    );
  });

  testWidgets('Hadith and Dua feature opens the combined library', (tester) async {
    await pumpFeatures(tester);
    await tester.scrollUntilVisible(
      find.text('হাদিস ও দোয়া'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await _openFeature(tester, 'হাদিস ও দোয়া');

    final libraryScreen = find.byType(HadithDuaScreen);
    expect(libraryScreen, findsOneWidget);
    expect(
      find.descendant(
        of: libraryScreen,
        matching: find.text('হাদিসের বিষয়সমূহ'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: libraryScreen,
        matching: find.text('দোয়ার বিষয়সমূহ'),
      ),
      findsOneWidget,
    );
  });
}
