import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../providers/hadith_provider.dart';

final _verifiedDuasProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/dua.json');
  final decoded = jsonDecode(raw) as List<dynamic>;
  return decoded
      .map((item) => item as Map<String, dynamic>)
      .where((item) => item['verified'] == true)
      .toList()
    ..sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
});

class HadithDuaScreen extends ConsumerWidget {
  const HadithDuaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final lang = strings.lang;
    final hadithAsync = ref.watch(hadithListProvider);
    final duaAsync = ref.watch(_verifiedDuasProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('hadith_dua'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            lang == 'bn' ? 'হাদিস' : 'Hadith',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          hadithAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(strings.t('daily_hadith_empty')),
            ),
            data: (hadithList) {
              if (hadithList.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(strings.t('daily_hadith_empty')),
                );
              }
              return Column(
                children: [
                  for (final hadith in hadithList) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    hadith.category,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  hadith.grade,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                hadith.arabicText,
                                textAlign: TextAlign.right,
                                style: theme.textTheme.headlineSmall?.copyWith(height: 1.8),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              lang == 'bn' ? hadith.banglaTranslation : hadith.englishTranslation,
                              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              hadith.narrator,
                              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${strings.t('source')}: ${hadith.source}  •  '
                              '${strings.t('reference')}: ${hadith.reference}',
                              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Text(
            lang == 'bn' ? 'দোয়া ও যিকির' : 'Dua and Dhikr',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          duaAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(lang == 'bn' ? 'দোয়া লোড করা যায়নি।' : 'Could not load duas.'),
            ),
            data: (duas) {
              if (duas.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(lang == 'bn' ? 'যাচাইকৃত দোয়া শিগগিরই যুক্ত হবে।' : 'Verified duas will be added soon.'),
                );
              }
              return Column(
                children: [
                  for (final dua in duas) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              lang == 'bn' ? dua['category_bn'] as String : dua['category_en'] as String,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                dua['arabic_text'] as String,
                                textAlign: TextAlign.right,
                                style: theme.textTheme.headlineSmall?.copyWith(height: 1.9),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              lang == 'bn'
                                  ? dua['bangla_translation'] as String
                                  : dua['english_translation'] as String,
                              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${strings.t('source')}: ${dua['source']}  •  '
                              '${strings.t('reference')}: ${dua['reference']}',
                              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
