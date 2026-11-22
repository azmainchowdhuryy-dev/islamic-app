import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:islamic_app/core/services/feedback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.azmain.islamic_app/feedback');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('Tasbih feedback requests sound and vibration together', () async {
    await FeedbackService.tap(
      vibration: true,
      sound: true,
      strong: false,
    );

    expect(calls, hasLength(1));
    expect(calls.single.method, 'playFeedback');
    expect(calls.single.arguments, {
      'vibration': true,
      'sound': true,
      'strong': false,
    });
  });

  test('target completion requests stronger vibration feedback', () async {
    await FeedbackService.tap(
      vibration: true,
      sound: true,
      strong: true,
    );

    expect(calls.single.arguments, {
      'vibration': true,
      'sound': true,
      'strong': true,
    });
  });

  test('disabled sound and vibration do not call the platform', () async {
    await FeedbackService.tap(
      vibration: false,
      sound: false,
    );

    expect(calls, isEmpty);
  });
}
