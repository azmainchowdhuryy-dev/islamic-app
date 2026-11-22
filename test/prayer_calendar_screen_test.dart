import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:islamic_app/features/calendar/screens/prayer_calendar_screen.dart';
import 'package:islamic_app/features/home/services/prayer_calculator.dart';

void main() {
  test('English digits are converted to Bengali digits', () {
    expect(toBanglaDigits('22-11-2026 05:07'), '২২-১১-২০২৬ ০৫:০৭');
  });

  test('non-digit characters remain unchanged', () {
    expect(toBanglaDigits('12:30 PM'), '১২:৩০ PM');
  });

  testWidgets('calendar uses saved calculation method and Shafi Asr setting',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'home_city': 'dhaka',
      'home_calc_method': PrayerCalculation.muslimWorldLeague.index,
      'home_hanafi': false,
    });
    await SharedPreferences.getInstance();

    await tester.pumpWidget(
      const MaterialApp(home: PrayerCalendarScreen()),
    );
    await tester.pumpAndSettle();

    final expected = DailyPrayerTimes.calculate(
      latitude: 23.8103,
      longitude: 90.4125,
      date: DateTime.now(),
      hanafi: false,
      method: PrayerCalculation.muslimWorldLeague,
    );
    final hour = expected.asr.hour % 12 == 0 ? 12 : expected.asr.hour % 12;
    final expectedAsr = toBanglaDigits(
      '${hour.toString().padLeft(2, '0')}:${expected.asr.minute.toString().padLeft(2, '0')}',
    );

    expect(
      tester.widget<Text>(find.byKey(const Key('calendar_asr_time'))).data,
      expectedAsr,
    );
    final calculationNoteFinder =
        find.byKey(const Key('calendar_calculation_method_note'));
    await tester.scrollUntilVisible(
      calculationNoteFinder,
      240,
      scrollable: find.descendant(
        of: find.byKey(const Key('prayer_calendar_scroll_view')),
        matching: find.byType(Scrollable),
      ),
    );
    final calculationNote =
        tester.widget<Text>(calculationNoteFinder).data!;
    expect(calculationNote, contains('মুসলিম ওয়ার্ল্ড লীগ'));
    expect(calculationNote, contains('শাফেয়ি'));
  });
}
