import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/services/prefs.dart';
import 'package:islamic_app/shared/widgets/main_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Home dashboard displays the redesigned prayer header and features', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: MainShell()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('বাংলা'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);
    expect(find.text('নামাজের সময়সূচি'), findsOneWidget);
    expect(find.text('টপ ফিচার'), findsOneWidget);
    expect(find.text('ট্র্যাকার'), findsOneWidget);
    expect(find.text('কিবলা'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
  });

  testWidgets('Five bottom tabs open their matching sections', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: MainShell()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ফিচার'));
    await tester.pumpAndSettle();
    expect(find.text('সব ফিচার'), findsOneWidget);

    await tester.tap(find.text('হাদিস'));
    await tester.pumpAndSettle();
    expect(find.text('হাদিসের বিষয়সমূহ'), findsOneWidget);
    expect(find.text('দোয়ার বিষয়সমূহ'), findsNothing);

    await tester.tap(find.text('দোয়া'));
    await tester.pumpAndSettle();
    expect(find.text('দোয়ার বিষয়সমূহ'), findsOneWidget);
    expect(find.text('হাদিসের বিষয়সমূহ'), findsNothing);
  });
}
