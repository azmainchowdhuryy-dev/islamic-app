import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../providers/settings_provider.dart';
import 'ibadah_tools_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider).t;
    final lang = ref.watch(stringsProvider).lang;
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(t('more'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.volunteer_activism_outlined)),
            title: Text(lang == 'bn' ? 'ইবাদত ও আল্লাহর ৯৯ নাম' : 'Worship & 99 Names of Allah'),
            subtitle: Text(lang == 'bn'
                ? 'নামাজ ট্র্যাকার, দৈনিক আমল ও প্রিয় নাম'
                : 'Prayer tracker, daily deeds and favorite names'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const IbadahToolsScreen()),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(t('language'), style: Theme.of(context).textTheme.titleMedium),
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
        Text(t('theme'), style: Theme.of(context).textTheme.titleMedium),
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
        Text(t('font_size'), style: Theme.of(context).textTheme.titleMedium),
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
