import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:islamic_app/core/services/prefs.dart';
import 'package:islamic_app/core/theme/app_theme.dart';
import 'package:islamic_app/features/hadith/models/hadith.dart';
import 'package:islamic_app/features/hadith/providers/hadith_provider.dart';
import 'package:islamic_app/features/hadith/screens/hadith_dua_screen.dart';
import 'package:islamic_app/features/home/screens/home_screen.dart';
import 'package:islamic_app/shared/widgets/main_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('bottom navigation has readable Light-theme colors', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        homeCitiesProvider.overrideWith(
          (ref) => const [
            HomeCity(
              id: 'dhaka',
              nameBn: 'ঢাকা',
              nameEn: 'Dhaka',
              lat: 23.8103,
              lng: 90.4125,
            ),
          ],
        ),
        hadithListProvider.overrideWith((ref) => <Hadith>[]),
        verifiedDuasProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[],
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        home: const MainShell(),
      ),
    ));
    await tester.pump();

    final scheme = AppTheme.light.colorScheme;
    final navigation = tester.widget<NavigationBarTheme>(
      find.byType(NavigationBarTheme),
    ).data;

    expect(navigation.backgroundColor, scheme.surface);
    expect(navigation.indicatorColor, scheme.primaryContainer);
    expect(
      navigation.labelTextStyle!.resolve({WidgetState.selected})!.color,
      scheme.primary,
    );
    expect(
      navigation.labelTextStyle!.resolve(<WidgetState>{})!.color,
      scheme.onSurfaceVariant,
    );
    expect(
      navigation.iconTheme!.resolve({WidgetState.selected})!.color,
      scheme.primary,
    );
    expect(
      navigation.iconTheme!.resolve(<WidgetState>{})!.color,
      scheme.onSurfaceVariant,
    );
  });
}
