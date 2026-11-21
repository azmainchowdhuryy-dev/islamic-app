import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/services/prefs.dart';
import 'package:islamic_app/shared/widgets/main_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _pumpMainShell(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: const MaterialApp(home: MainShell()),
  ));
  // Wait for the bundled city data without pumpAndSettle because the
  // Home countdown intentionally has a live one-second timer.
  for (var i = 0;
      i < 20 && find.text('নামাজের সময়সূচি').evaluate().isEmpty;
      i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(find.text('নামাজের সময়সূচি'), findsOneWidget);
  return prefs;
}

void main() {
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
