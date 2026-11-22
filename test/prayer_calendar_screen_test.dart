import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/features/calendar/screens/prayer_calendar_screen.dart';

void main() {
  test('English digits are converted to Bengali digits', () {
    expect(toBanglaDigits('22-11-2026 05:07'), '২২-১১-২০২৬ ০৫:০৭');
  });

  test('non-digit characters remain unchanged', () {
    expect(toBanglaDigits('12:30 PM'), '১২:৩০ PM');
  });
}
