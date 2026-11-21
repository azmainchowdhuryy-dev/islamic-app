import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/services/prefs.dart';
import 'package:islamic_app/features/settings/screens/more_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('More screen keeps settings and removes duplicate worship shortcuts', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: MoreScreen()),
    ));
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
