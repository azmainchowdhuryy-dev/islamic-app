import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/services/prefs.dart';
import 'package:islamic_app/features/tools/screens/features_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Features screen exposes all requested tools', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: FeaturesScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('সব ফিচার'), findsOneWidget);
    expect(find.text('আজকের নামাজ'), findsOneWidget);
    expect(find.text('দৈনিক আমল'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('কিবলা'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('কিবলা'), findsOneWidget);
    expect(find.text('রুকইয়াহ'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('তাসবিহ'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('আল্লাহর ৯৯ নাম'), findsOneWidget);
    expect(find.text('তাসবিহ'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('হাদিস ও দোয়া'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('হাদিস ও দোয়া'), findsOneWidget);
  });
}
