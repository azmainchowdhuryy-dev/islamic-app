import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../hadith/providers/hadith_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(stringsProvider).lang;
    final t = ref.watch(stringsProvider).t;
    final hadith = ref.watch(hadithListProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t('greeting'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: ListTile(
            title: Text(t('next_prayer')),
            subtitle: Text(t('coming_soon')),
          ),
        ),
        Card(
          child: ListTile(
            title: Text(t('daily_hadith')),
            subtitle: hadith.when(
              data: (l) => Text(l.isEmpty
                  ? t('coming_soon')
                  : (lang == 'bn'
                      ? l.first.banglaTranslation
                      : l.first.englishTranslation)),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => const Text('Error'),
            ),
          ),
        ),
        Card(
          child: ListTile(
            title: Text(t('todays_prayers')),
            subtitle: Text(t('coming_soon')),
          ),
        ),
      ]),
    );
  }
}
