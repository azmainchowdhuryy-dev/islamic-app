import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/services/prefs.dart';
import 'package:islamic_app/features/settings/screens/more_screen.dart';
import 'package:islamic_app/features/settings/screens/logo_preview_screen.dart';
import 'package:islamic_app/shared/widgets/islamic_logo_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('More screen uses the approved app logo and keeps settings',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: MoreScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(IslamicAppLogo), findsOneWidget);
    final logoImage = tester.widget<Image>(
      find.descendant(
        of: find.byType(IslamicAppLogo),
        matching: find.byType(Image),
      ),
    );
    expect(logoImage.image, isA<AssetImage>());
    expect(
      (logoImage.image as AssetImage).assetName,
      'assets/images/islamic_app_logo.webp',
    );

    await tester.tap(find.byKey(const Key('more_logo_preview')));
    await tester.pumpAndSettle();

    expect(find.byType(LogoPreviewScreen), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor,
      Colors.white,
    );
    expect(
      find.descendant(
        of: find.byType(IslamicAppLogo),
        matching: find.byType(Image),
      ),
      findsNWidgets(1),
    );

    Navigator.of(tester.element(find.byType(LogoPreviewScreen))).pop();
    await tester.pumpAndSettle();

    expect(find.text('আরও'), findsOneWidget);
    expect(find.text('ভাষা'), findsOneWidget);
    expect(find.text('থিম'), findsOneWidget);
    expect(find.text('ফন্টের আকার'), findsOneWidget);
    expect(find.text('ইবাদত ও আল্লাহর ৯৯ নাম'), findsNothing);
    expect(find.text('নামাজ ট্র্যাকার, দৈনিক আমল ও প্রিয় নাম'), findsNothing);
    expect(find.text('দৈনিক আমল'), findsNothing);
    expect(find.text('আল্লাহর ৯৯ নাম'), findsNothing);
  });
}
