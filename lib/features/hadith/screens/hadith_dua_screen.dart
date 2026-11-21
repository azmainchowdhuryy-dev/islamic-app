import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../models/hadith.dart';
import '../providers/hadith_provider.dart';

final verifiedDuasProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/dua.json');
  final decoded = jsonDecode(raw) as List<dynamic>;
  return decoded
      .map((item) => item as Map<String, dynamic>)
      .where((item) => item['verified'] == true)
      .toList()
    ..sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
});

enum HadithDuaSection { all, hadith, dua }

class HadithDuaScreen extends ConsumerStatefulWidget {
  final HadithDuaSection section;

  const HadithDuaScreen({super.key, this.section = HadithDuaSection.all});

  @override
  ConsumerState<HadithDuaScreen> createState() => _HadithDuaScreenState();
}

class _HadithDuaScreenState extends ConsumerState<HadithDuaScreen> {
  String? _hadithCategory;
  String? _duaCategory;

  Widget _topicChips({
    required String? selected,
    required List<String> categories,
    required String allLabel,
    required ValueChanged<String?> onSelected,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: Text(allLabel),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          for (final category in categories) ...[
            ChoiceChip(
              label: Text(category),
              selected: selected == category,
              onSelected: (_) => onSelected(category),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _hadithCard(BuildContext context, Hadith hadith, String lang) {
    final strings = ref.read(stringsProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lang == 'bn' ? hadith.category : hadith.categoryEn,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (hadith.grade.isNotEmpty)
                  Text(
                    hadith.grade,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            if (hadith.arabicText.isNotEmpty) ...[
              const SizedBox(height: 14),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  hadith.arabicText,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.headlineSmall?.copyWith(height: 1.8),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              lang == 'bn' ? hadith.banglaTranslation : hadith.englishTranslation,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
            if (hadith.narrator.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                hadith.narrator,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '${strings.t('source')}: ${hadith.source}  •  '
              '${strings.t('reference')}: ${hadith.reference}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _duaCard(BuildContext context, Map<String, dynamic> dua, String lang) {
    final strings = ref.read(stringsProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              lang == 'bn'
                  ? dua['category_bn'] as String
                  : dua['category_en'] as String,
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
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final lang = strings.lang;
    final hadithAsync = widget.section == HadithDuaSection.dua
        ? const AsyncData<List<Hadith>>([])
        : ref.watch(hadithListProvider);
    final duaAsync = widget.section == HadithDuaSection.hadith
        ? const AsyncData<List<Map<String, dynamic>>>([])
        : ref.watch(verifiedDuasProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.section == HadithDuaSection.hadith
            ? strings.t('hadith')
            : widget.section == HadithDuaSection.dua
                ? strings.t('dua')
                : strings.t('hadith_dua')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.section != HadithDuaSection.dua) ...[
          Text(
            lang == 'bn' ? 'হাদিসের বিষয়সমূহ' : 'Hadith Topics',
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
              final categories = hadithList
                  .map((item) => lang == 'bn' ? item.category : item.categoryEn)
                  .toSet()
                  .toList();
              final selectedBn = _hadithCategory;
              final selectedDisplay = selectedBn == null
                  ? null
                  : (lang == 'bn'
                      ? selectedBn
                      : hadithList
                          .firstWhere((item) => item.category == selectedBn)
                          .categoryEn);
              final filtered = selectedBn == null
                  ? hadithList
                  : hadithList.where((item) => item.category == selectedBn).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _topicChips(
                    selected: selectedDisplay,
                    categories: categories,
                    allLabel: lang == 'bn' ? 'সব হাদিস' : 'All Hadith',
                    onSelected: (value) {
                      setState(() {
                        _hadithCategory = value == null
                            ? null
                            : hadithList
                                .firstWhere((item) =>
                                    (lang == 'bn' ? item.category : item.categoryEn) == value)
                                .category;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lang == 'bn' ? '${filtered.length}টি হাদিস' : '${filtered.length} hadith',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  for (final hadith in filtered) ...[
                    _hadithCard(context, hadith, lang),
                    const SizedBox(height: 10),
                  ],
                  if (hadithList.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(
                        lang == 'bn'
                            ? 'হাদিসগুলো সহিহ বুখারি ও সহিহ মুসলিমের উল্লেখিত রেফারেন্স অনুযায়ী সাজানো হয়েছে। অনুবাদগুলো সংক্ষিপ্ত ভাবানুবাদ।'
                            : 'Each hadith displays its cited collection, reference and grade. Translations are concise project paraphrases.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              );
            },
          ),
          ],
          if (widget.section != HadithDuaSection.hadith) ...[
          const SizedBox(height: 18),
          Text(
            lang == 'bn' ? 'দোয়ার বিষয়সমূহ' : 'Dua Topics',
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
              final categories = duas
                  .map((item) => lang == 'bn'
                      ? item['category_bn'] as String
                      : item['category_en'] as String)
                  .toSet()
                  .toList();
              final selectedBn = _duaCategory;
              final selectedDisplay = selectedBn == null
                  ? null
                  : (lang == 'bn'
                      ? selectedBn
                      : duas.firstWhere(
                          (item) => item['category_bn'] == selectedBn,
                        )['category_en'] as String);
              final filtered = selectedBn == null
                  ? duas
                  : duas.where((item) => item['category_bn'] == selectedBn).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _topicChips(
                    selected: selectedDisplay,
                    categories: categories,
                    allLabel: lang == 'bn' ? 'সব দোয়া' : 'All Duas',
                    onSelected: (value) {
                      setState(() {
                        _duaCategory = value == null
                            ? null
                            : duas
                                .firstWhere((item) =>
                                    (lang == 'bn'
                                        ? item['category_bn']
                                        : item['category_en']) == value)['category_bn'] as String;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lang == 'bn' ? '${filtered.length}টি দোয়া' : '${filtered.length} duas',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  for (final dua in filtered) ...[
                    _duaCard(context, dua, lang),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
          ],
        ],
      ),
    );
  }
}
