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

  testWidgets('ibadah tools renders prayer tracker and all 99 names', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: IbadahToolsScreen()),
    ));
    await tester.pumpAndSettle();

    // Check the prayer tracker while it is on screen. Scrolling to the names
    // section first can dispose earlier off-screen ListView children.
    expect(find.text('পাঁচ ওয়াক্ত নামাজের হিসাব'), findsOneWidget);
    expect(find.text('ফজর'), findsOneWidget);

    // Bring the names section into the widget tree before checking its rows.
    await tester.scrollUntilVisible(
      find.text('আল্লাহর সুন্দর নামসমূহ'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('আল্লাহর সুন্দর নামসমূহ'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(99));
  });

  testWidgets('name search filters the list', (tester) async {
    final prefs = await SharedPreferences.getInstance();
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

    // Match the result row only, not the editable search field itself.
    expect(find.text('Ar-Rahman • পরম করুণাময়'), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
  });
}
