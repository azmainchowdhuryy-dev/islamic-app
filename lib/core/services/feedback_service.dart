import 'package:flutter/services.dart';

/// Native Android feedback for the Tasbih counter.
class FeedbackService {
  static const MethodChannel _channel =
      MethodChannel('com.azmain.islamic_app/feedback');

  static Future<void> tap({
    required bool vibration,
    required bool sound,
    bool strong = false,
  }) async {
    if (!vibration && !sound) return;

    try {
      await _channel.invokeMethod<void>('playFeedback', {
        'vibration': vibration,
        'sound': sound,
        'strong': strong,
      });
    } on MissingPluginException {
      // The UI must remain usable on platforms without the Android bridge.
    } on PlatformException {
      // Audio or vibration hardware may be unavailable or disabled by the OS.
    }
  }
}
