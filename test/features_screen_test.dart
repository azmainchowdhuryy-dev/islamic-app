import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/services/prefs.dart';
import 'package:islamic_app/features/tools/screens/features_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _openFeature(
  WidgetTester tester,
  String label,
) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpFeatures(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: FeaturesScreen()),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('Features screen exposes all requested tools', (tester) async {
    await pumpFeatures(tester);

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

  testWidgets('Prayer tracker feature opens only prayer section', (tester) async {
    await pumpFeatures(tester);
    await _openFeature(tester, 'আজকের নামাজ');

    expect(find.text('আজকের নামাজ'), findsOneWidget);
    expect(find.text('পাঁচ ওয়াক্ত নামাজের হিসাব'), findsOneWidget);
    expect(find.text('দৈনিক আমল'), findsNothing);
    expect(find.text('আল্লাহর সুন্দর নামসমূহ'), findsNothing);
  });

  testWidgets('Daily Amal feature opens only its checklist', (tester) async {
    await pumpFeatures(tester);
    await _openFeature(tester, 'দৈনিক আমল');

    expect(find.text('দৈনিক আমল'), findsOneWidget);
    expect(find.text('আজকের আমলের তালিকা'), findsOneWidget);
    expect(find.text('পাঁচ ওয়াক্ত নামাজের হিসাব'), findsNothing);
    expect(find.text('আল্লাহর সুন্দর নামসমূহ'), findsNothing);
  });

  testWidgets('Allah names feature opens only the 99 names list', (tester) async {
    await pumpFeatures(tester);
    await tester.scrollUntilVisible(
      find.text('আল্লাহর ৯৯ নাম'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('আল্লাহর ৯৯ নাম'));
    await tester.pumpAndSettle();

    expect(find.text('আল্লাহর সুন্দর নামসমূহ'), findsOneWidget);
    expect(find.text('পাঁচ ওয়াক্ত নামাজের হিসাব'), findsNothing);
    expect(find.text('দৈনিক আমল'), findsNothing);
  });
}
