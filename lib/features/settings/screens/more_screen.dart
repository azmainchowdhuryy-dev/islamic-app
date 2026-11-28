import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/services/noor_notification_service.dart';
import '../../../core/services/prefs.dart';
import '../../../core/navigation/navigation_provider.dart';
import '../../../shared/widgets/islamic_logo_widget.dart';
import '../providers/settings_provider.dart';
import 'logo_preview_screen.dart';

class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  late bool _prayerNotifications;
  late bool _adhkarNotifications;
  late int _morningHour;
  late int _morningMinute;
  late int _eveningHour;
  late int _eveningMinute;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPrefsProvider);
    _prayerNotifications =
        prefs.getBool('notifications_prayer_enabled') ?? false;
    _adhkarNotifications =
        prefs.getBool('notifications_adhkar_enabled') ?? false;
    _morningHour = prefs.getInt('adhkar_morning_hour') ?? 6;
    _morningMinute = prefs.getInt('adhkar_morning_minute') ?? 0;
    _eveningHour = prefs.getInt('adhkar_evening_hour') ?? 18;
    _eveningMinute = prefs.getInt('adhkar_evening_minute') ?? 0;
  }

  Future<void> _setNotification(String key, bool value) async {
    if (value) {
      final granted =
          await NoorNotificationService.instance.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('নোটিফিকেশন অনুমতি না দিলে রিমাইন্ডার চালু হবে না।'),
            ),
          );
        }
        return;
      }
    }
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool(key, value);
    ref.read(notificationSettingsRevisionProvider.notifier).state++;
    if (!mounted) return;
    setState(() {
      if (key == 'notifications_prayer_enabled') {
        _prayerNotifications = value;
      } else {
        _adhkarNotifications = value;
      }
    });
    await NoorNotificationService.instance.syncFromPreferences(prefs);
  }

  Future<void> _chooseReminderTime({required bool morning}) async {
    final initial = TimeOfDay(
      hour: morning ? _morningHour : _eveningHour,
      minute: morning ? _morningMinute : _eveningMinute,
    );
    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: morning ? 'সকালের রিমাইন্ডারের সময়' : 'সন্ধ্যার রিমাইন্ডারের সময়',
    );
    if (selected == null) return;

    final prefs = ref.read(sharedPrefsProvider);
    if (morning) {
      await prefs.setInt('adhkar_morning_hour', selected.hour);
      await prefs.setInt('adhkar_morning_minute', selected.minute);
    } else {
      await prefs.setInt('adhkar_evening_hour', selected.hour);
      await prefs.setInt('adhkar_evening_minute', selected.minute);
    }
    if (!mounted) return;
    setState(() {
      if (morning) {
        _morningHour = selected.hour;
        _morningMinute = selected.minute;
      } else {
        _eveningHour = selected.hour;
        _eveningMinute = selected.minute;
      }
    });
    if (_adhkarNotifications) {
      await NoorNotificationService.instance.syncFromPreferences(prefs);
    }
  }

  String _timeLabel(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final shownHour = hour % 12 == 0 ? 12 : hour % 12;
    return '${shownHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(notificationSettingsRevisionProvider);
    final prefs = ref.read(sharedPrefsProvider);
    final prayerEnabled = prefs.getBool('notifications_prayer_enabled') ?? false;
    final adhkarEnabled = prefs.getBool('notifications_adhkar_enabled') ?? false;
    final t = ref.watch(stringsProvider).t;
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t('more'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const Key('more_logo_preview'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LogoPreviewScreen(),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const IslamicAppLogo(size: 64),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Noor',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.lang == 'bn'
                              ? 'ইসলামিক শিক্ষা ও ইবাদতের সঙ্গী'
                              : 'Your companion for Islamic learning and worship',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.open_in_full,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          s.lang == 'bn' ? 'নোটিফিকেশন' : 'Notifications',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                key: const Key('prayer_notifications_switch'),
                title: Text(s.lang == 'bn'
                    ? 'পাঁচ ওয়াক্ত নামাজের নোটিফিকেশন'
                    : 'Five daily prayer notifications'),
                subtitle: Text(s.lang == 'bn'
                    ? 'প্রতিটি ওয়াক্ত শুরু হলে জানাবে'
                    : 'Alert when each prayer time begins'),
                value: prayerEnabled,
                onChanged: (value) =>
                    _setNotification('notifications_prayer_enabled', value),
              ),
              const Divider(height: 1),
              SwitchListTile(
                key: const Key('adhkar_notifications_switch'),
                title: Text(s.lang == 'bn'
                    ? 'সকাল-সন্ধ্যার আমলের রিমাইন্ডার'
                    : 'Morning and evening adhkar reminders'),
                subtitle: Text(s.lang == 'bn'
                    ? 'প্রতিদিন দুই সময়ে মনে করিয়ে দেবে'
                    : 'A daily reminder at two selected times'),
                value: adhkarEnabled,
                onChanged: (value) =>
                    _setNotification('notifications_adhkar_enabled', value),
              ),
              if (adhkarEnabled) ...[
                const Divider(height: 1),
                ListTile(
                  key: const Key('morning_adhkar_time'),
                  leading: const Icon(Icons.wb_sunny_outlined),
                  title: Text(s.lang == 'bn' ? 'সকালের সময়' : 'Morning time'),
                  trailing: Text(_timeLabel(_morningHour, _morningMinute)),
                  onTap: () => _chooseReminderTime(morning: true),
                ),
                ListTile(
                  key: const Key('evening_adhkar_time'),
                  leading: const Icon(Icons.nights_stay_outlined),
                  title: Text(s.lang == 'bn' ? 'সন্ধ্যার সময়' : 'Evening time'),
                  trailing: Text(_timeLabel(_eveningHour, _eveningMinute)),
                  onTap: () => _chooseReminderTime(morning: false),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(t('language'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'bn', label: Text('বাংলা')),
            ButtonSegment(value: 'en', label: Text('English')),
          ],
          selected: {s.lang},
          onSelectionChanged: (v) => n.setLang(v.first),
        ),
        const SizedBox(height: 24),
        Text(t('theme'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: [
            ButtonSegment(value: ThemeMode.system, label: Text(t('theme_system'))),
            ButtonSegment(value: ThemeMode.light, label: Text(t('theme_light'))),
            ButtonSegment(value: ThemeMode.dark, label: Text(t('theme_dark'))),
          ],
          selected: {s.themeMode},
          onSelectionChanged: (v) => n.setThemeMode(v.first),
        ),
        const SizedBox(height: 24),
        Text(t('font_size'), style: theme.textTheme.titleMedium),
        Slider(
          value: s.fontScale,
          min: 0.85,
          max: 1.4,
          divisions: 11,
          onChanged: n.setFontScale,
        ),
      ]),
    );
  }
}
