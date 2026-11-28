import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../time/bangladesh_clock.dart';
import '../navigation/noor_navigator.dart';
import '../../features/hadith/screens/hadith_dua_screen.dart';
import '../../features/home/services/prayer_calculator.dart';

/// Local notification scheduler for Noor. All schedules use Bangladesh time.
class NoorNotificationService {
  NoorNotificationService._();

  static final NoorNotificationService instance = NoorNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const int _prayerIdBase = 10000;
  static const int _prayerScheduleDays = 30;
  static const int _morningReminderId = 30001;
  static const int _eveningReminderId = 30002;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher_v3'),
    );
    try {
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (response) {
          if (response.payload == 'morning_evening_adhkar') {
            openMorningEveningAdhkar();
          }
        },
      );
    } on MissingPluginException {
      // Widget tests and unsupported platforms may not register the Android plugin.
    }
    try {
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true &&
          launchDetails?.notificationResponse?.payload == 'morning_evening_adhkar') {
        pendingMorningEveningAdhkarOpen = true;
      }
    } on MissingPluginException {
      // Ignore launch details where the platform plugin is unavailable.
    }
    _initialized = true;
  }

  void openMorningEveningAdhkar() {
    final navigator = noorNavigatorKey.currentState;
    if (navigator == null) {
      pendingMorningEveningAdhkarOpen = true;
      return;
    }
    pendingMorningEveningAdhkarOpen = false;
    navigator.push(MaterialPageRoute<void>(
      builder: (_) => const HadithDuaScreen(
        section: HadithDuaSection.morningEveningDua,
      ),
    ));
  }

  void consumePendingNotificationNavigation() {
    if (pendingMorningEveningAdhkarOpen) openMorningEveningAdhkar();
  }

  Future<bool> requestPermission() async {
    await initialize();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> syncFromPreferences(SharedPreferences prefs) async {
    await initialize();
    try {
      if (prefs.getBool('notifications_adhkar_enabled') ?? false) {
        await scheduleAdhkarReminders(
          morningHour: prefs.getInt('adhkar_morning_hour') ?? 6,
          morningMinute: prefs.getInt('adhkar_morning_minute') ?? 0,
          eveningHour: prefs.getInt('adhkar_evening_hour') ?? 18,
          eveningMinute: prefs.getInt('adhkar_evening_minute') ?? 0,
        );
      } else {
        await _plugin.cancel(_morningReminderId);
        await _plugin.cancel(_eveningReminderId);
      }

      if (prefs.getBool('notifications_prayer_enabled') ?? false) {
        await _schedulePrayerNotificationsFromPreferences(prefs);
      } else {
        await _cancelPrayerNotifications();
      }
    } on MissingPluginException {
      // Keep notification preferences usable in tests and on unsupported platforms.
    }
  }

  Future<void> scheduleAdhkarReminders({
    required int morningHour,
    required int morningMinute,
    required int eveningHour,
    required int eveningMinute,
  }) async {
    await initialize();
    await _scheduleDaily(
      id: _morningReminderId,
      hour: morningHour,
      minute: morningMinute,
      title: 'সকালের যিকিরের সময়',
      body: 'সকালের মাসনুন যিকির ও দোয়া পড়ে নিন।',
      payload: 'morning_evening_adhkar',
    );
    await _scheduleDaily(
      id: _eveningReminderId,
      hour: eveningHour,
      minute: eveningMinute,
      title: 'সন্ধ্যার যিকিরের সময়',
      body: 'সন্ধ্যার মাসনুন যিকির ও দোয়া পড়ে নিন।',
      payload: 'morning_evening_adhkar',
    );
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    String? payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _notificationDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _schedulePrayerNotificationsFromPreferences(
    SharedPreferences prefs,
  ) async {
    final raw = await rootBundle.loadString('assets/data/cities_bd.json');
    final cities = (jsonDecode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final cityId = prefs.getString('home_city') ?? 'dhaka';
    final city = cities.firstWhere(
      (item) => item['id'] == cityId,
      orElse: () => cities.first,
    );
    final methodIndex = (prefs.getInt('home_calc_method') ?? 0)
        .clamp(0, PrayerCalculation.values.length - 1)
        .toInt();
    final method = PrayerCalculation.values[methodIndex];
    final hanafi = prefs.getBool('home_hanafi') ?? true;
    await schedulePrayerNotifications(
      latitude: (city['lat'] as num).toDouble(),
      longitude: (city['lng'] as num).toDouble(),
      hanafi: hanafi,
      method: method,
    );
  }

  Future<void> schedulePrayerNotifications({
    required double latitude,
    required double longitude,
    required bool hanafi,
    required PrayerCalculation method,
  }) async {
    await initialize();
    await _cancelPrayerNotifications();
    final now = bangladeshWallClock(DateTime.now());
    final today = DateTime(now.year, now.month, now.day);

    for (var dayOffset = 0; dayOffset < _prayerScheduleDays; dayOffset++) {
      final date = today.add(Duration(days: dayOffset));
      final prayers = DailyPrayerTimes.calculate(
        latitude: latitude,
        longitude: longitude,
        date: date,
        hanafi: hanafi,
        method: method,
      );
      final entries = prayers.entries();
      for (var index = 0; index < entries.length; index++) {
        final entry = entries[index];
        final time = entry.value;
        final scheduled = tz.TZDateTime(
          tz.local,
          time.year,
          time.month,
          time.day,
          time.hour,
          time.minute,
        );
        if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) continue;
        await _plugin.zonedSchedule(
          _prayerIdBase + dayOffset * 5 + index,
          'নামাজের সময়: ${_prayerName(entry.key)}',
          '${_prayerName(entry.key)}-এর ওয়াক্ত শুরু হয়েছে। নামাজ আদায় করুন।',
          scheduled,
          _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }
  }

  String _prayerName(String key) {
    switch (key) {
      case 'fajr':
        return 'ফজর';
      case 'dhuhr':
        return 'যোহর';
      case 'asr':
        return 'আসর';
      case 'maghrib':
        return 'মাগরিব';
      case 'isha':
        return 'ইশা';
      default:
        return key;
    }
  }

  Future<void> _cancelPrayerNotifications() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.id >= _prayerIdBase &&
          request.id < _prayerIdBase + _prayerScheduleDays * 5) {
        await _plugin.cancel(request.id);
      }
    }
  }

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'noor_reminders',
      'Noor Reminders',
      channelDescription: 'Prayer time and daily adhkar reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    ),
  );
}
