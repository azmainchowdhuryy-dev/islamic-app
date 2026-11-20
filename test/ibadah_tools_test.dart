import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/services/prefs.dart';
import 'package:islamic_app/features/settings/screens/ibadah_tools_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ibadah tools renders all 99 names and daily trackers', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: IbadahToolsScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('99 Names of Allah'), findsNothing);
    expect(find.textContaining('আল্লাহর সুন্দর নামসমূহ'), findsOneWidget);
    expect(find.text('ফজর'), findsOneWidget);
    expect(find.text('কুরআন তিলাওয়াত'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(99));
  });

  testWidgets('name search filters the list', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: IbadahToolsScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Ar-Rahman');
    await tester.pumpAndSettle();

    expect(find.textContaining('Ar-Rahman'), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
  });
}
