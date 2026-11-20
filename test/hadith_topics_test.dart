import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/services/prefs.dart';
import 'package:islamic_app/features/hadith/screens/hadith_dua_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Hadith and Dua screens show separate topic collections', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: HadithDuaScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('হাদিসের বিষয়সমূহ'), findsOneWidget);
    // The topic is shown in the filter chip and again on the Hadith card.
    expect(
      find.descendant(
        of: find.byType(ChoiceChip),
        matching: find.text('নিয়ত'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(Card),
        matching: find.text('নিয়ত'),
      ),
      findsWidgets,
    );

    await tester.scrollUntilVisible(
      find.text('দোয়ার বিষয়সমূহ'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('দোয়ার বিষয়সমূহ'), findsOneWidget);
    // The dua topic appears in both its filter chip and its matching dua card.
    expect(
      find.descendant(
        of: find.byType(ChoiceChip),
        matching: find.text('মা-বাবার জন্য দোয়া'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(Card),
        matching: find.text('মা-বাবার জন্য দোয়া'),
      ),
      findsWidgets,
    );
  });
}
