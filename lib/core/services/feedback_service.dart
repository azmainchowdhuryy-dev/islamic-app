import 'package:flutter/services.dart';

/// কম্পন ও শব্দ। Flutter-এর নিজস্ব API ব্যবহার করে, তাই কোনো নতুন প্যাকেজ বা
/// Android Permission লাগে না।
class FeedbackService {
  static Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // কম্পন/শব্দ না চললেও অ্যাপ যেন ক্র্যাশ না করে।
    }
  }

  /// [strong] = true হলে জোরালো কম্পন (লক্ষ্য পূর্ণ হলে)।
  static void tap({required bool vibration, required bool sound, bool strong = false}) {
    if (vibration) {
      _safe(() => strong ? HapticFeedback.heavyImpact() : HapticFeedback.lightImpact());
    }
    if (sound) {
      _safe(() => SystemSound.play(SystemSoundType.click));
    }
  }
}
