import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/services/prefs.dart';
import 'package:islamic_app/core/theme/app_colors.dart';
import 'package:islamic_app/core/theme/app_theme.dart';
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

  Future<void> pumpFeatures(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        hadithListProvider.overrideWith((ref) => <Hadith>[]),
        verifiedDuasProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[],
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: const FeaturesScreen(),
      ),
    ));
    await tester.pump();
  }


  testWidgets('Feature icons remain visible in Light and System themes', (tester) async {
    tester.binding.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.binding.platformDispatcher.clearPlatformBrightnessTestValue);

    for (final mode in [ThemeMode.light, ThemeMode.system]) {
      await pumpFeatures(tester, themeMode: mode);
      final avatars = find.byType(CircleAvatar);
      expect(avatars, findsWidgets);

      for (var i = 0; i < avatars.evaluate().length; i++) {
        final avatar = tester.widget<CircleAvatar>(avatars.at(i));
        expect(avatar.backgroundColor, AppTheme.light.colorScheme.primaryContainer);
        final icon = tester.widget<Icon>(
          find.descendant(of: avatars.at(i), matching: find.byType(Icon)),
        );
        expect(icon.color, AppTheme.light.colorScheme.onPrimaryContainer);
      }
    }

    // Recreate the app after changing the platform brightness so the System
    // theme is resolved from the updated test device brightness.
    tester.binding.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpFeatures(tester, themeMode: ThemeMode.system);
    final darkAvatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar).first);
    expect(darkAvatar.backgroundColor, AppColors.iconBadge);
    final darkIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byType(CircleAvatar).first,
        matching: find.byType(Icon),
      ),
    );
    expect(darkIcon.color, AppColors.primaryAccent);
  });

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
    expect(find.text("Allah's 99 Names"), findsOneWidget);
    expect(find.text('তাসবিহ'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('হাদিস ও দোয়া'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('হাদিস ও দোয়া'), findsOneWidget);
  });

  testWidgets('Prayer tracker feature opens both worship checklists', (tester) async {
    await pumpFeatures(tester);
    await _openFeature(tester, 'আজকের নামাজ');

    final trackerScreen = find.byType(IbadahToolsScreen);
    expect(trackerScreen, findsOneWidget);
    expect(
      find.descendant(of: trackerScreen, matching: find.text('ইবাদত ট্র্যাকার')),
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
      find.descendant(of: trackerScreen, matching: find.text('আজকের আমলের তালিকা')),
      findsOneWidget,
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
      find.text("Allah's 99 Names"),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await _openFeature(tester, "Allah's 99 Names");

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
