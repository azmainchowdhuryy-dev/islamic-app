import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/widgets/islamic_logo_widget.dart';
import '../providers/settings_provider.dart';
import 'logo_preview_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider).t;
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
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
                          'Islamic App',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.lang == 'bn'
                              ? 'ইসলামিক শিক্ষা ও ইবাদতের সঙ্গী'
                              : 'Your companion for Islamic learning and worship',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.open_in_full,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
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
