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

enum HadithDuaSection { all, hadith, dua, morningEveningDua, dailyDua }

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
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(allLabel),
          selected: selected == null,
          onSelected: (_) => onSelected(null),
        ),
        for (final category in categories)
          ChoiceChip(
            label: Text(category),
            selected: selected == category,
            onSelected: (_) => onSelected(category),
          ),
      ],
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
              hadith.translationSource.startsWith('Noor-এর নিজস্ব')
                  ? (lang == 'bn' ? 'সংক্ষিপ্ত বাংলা ভাবার্থ' : 'Concise meaning')
                  : (lang == 'bn' ? 'বাংলা অর্থ' : 'English meaning'),
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
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
            if ((dua['title_bn'] as String? ?? '').isNotEmpty) ...[
              Text(
                lang == 'bn'
                    ? dua['title_bn'] as String
                    : dua['category_en'] as String,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 4),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                dua['arabic_text'] as String,
                textAlign: TextAlign.right,
                style: theme.textTheme.headlineSmall?.copyWith(height: 1.9),
              ),
            ),
            if ((dua['transliteration_bn'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'উচ্চারণ: ${dua['transliteration_bn']}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              lang == 'bn' || (dua['english_translation'] as String? ?? '').isEmpty
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
    final isDuaOnly = widget.section == HadithDuaSection.dua ||
        widget.section == HadithDuaSection.morningEveningDua ||
        widget.section == HadithDuaSection.dailyDua;
    final hadithAsync = isDuaOnly
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
            : widget.section == HadithDuaSection.morningEveningDua
                ? (lang == 'bn' ? 'সকাল-সন্ধ্যার দোয়া' : 'Morning & Evening Duas')
                : widget.section == HadithDuaSection.dailyDua
                    ? (lang == 'bn' ? 'দৈনন্দিন ব্যবহার' : 'Daily Use')
                    : widget.section == HadithDuaSection.dua
                        ? strings.t('dua')
                        : strings.t('hadith_dua')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!isDuaOnly) ...[
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
                            ? 'দীর্ঘ বর্ণনার ক্ষেত্রে প্রাসঙ্গিক আরবি অংশ দেখানো হয়েছে। প্রতিটি হাদিসের গ্রন্থ ও পূর্ণ রেফারেন্স দেওয়া আছে। বাংলা ও ইংরেজি অর্থ সংক্ষিপ্ত ভাবানুবাদ।'
                            : 'For longer narrations, a relevant Arabic excerpt is shown with the full collection reference. Bengali and English meanings are concise project paraphrases.',
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
            widget.section == HadithDuaSection.morningEveningDua
                ? (lang == 'bn' ? 'সকাল-সন্ধ্যা' : 'Morning & Evening')
                : (lang == 'bn' ? 'দোয়ার বিষয়সমূহ' : 'Dua Topics'),
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
            data: (allDuas) {
              final duas = allDuas.where((item) {
                final usage = item['usage_category'] as String? ??
                    (item['id'] == 'hisn-78' ? 'morning_evening' : 'daily');
                if (widget.section == HadithDuaSection.morningEveningDua) {
                  return usage == 'morning_evening';
                }
                if (widget.section == HadithDuaSection.dailyDua) {
                  return usage == 'daily';
                }
                return true;
              }).toList();
              final categories = duas
                  .map((item) => item['category_bn'] as String)
                  .toSet()
                  .toList()
                ..sort();
              final selectedBn = _duaCategory;
              final filtered = selectedBn == null
                  ? <Map<String, dynamic>>[]
                  : duas.where((item) => item['category_bn'] == selectedBn).toList();
              if (selectedBn == null && widget.section != HadithDuaSection.morningEveningDua) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      lang == 'bn' ? '${duas.length}টি দোয়া' : '${duas.length} duas',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    for (final category in categories) ...[
                      Builder(builder: (context) {
                        final categoryDuas = duas
                            .where((item) => item['category_bn'] == category)
                            .toList();
                        final englishName = categoryDuas.first['category_en'] as String;
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              foregroundColor: theme.colorScheme.onPrimaryContainer,
                              child: const Icon(Icons.folder_open_rounded),
                            ),
                            title: Text(lang == 'bn' ? category : englishName),
                            subtitle: Text(
                              lang == 'bn'
                                  ? '${categoryDuas.length}টি দোয়া'
                                  : '${categoryDuas.length} duas',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => setState(() => _duaCategory = category),
                          ),
                        );
                      }),
                    ],
                  ],
                );
              }
              final visibleDuas = widget.section == HadithDuaSection.morningEveningDua
                  ? duas
                  : filtered;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.section != HadithDuaSection.morningEveningDua)
                    TextButton.icon(
                      onPressed: () => setState(() => _duaCategory = null),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(lang == 'bn' ? 'সব বিষয়' : 'All topics'),
                      style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                    ),
                  Text(
                    lang == 'bn'
                        ? '${visibleDuas.length}টি দোয়া'
                        : '${visibleDuas.length} duas',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  for (final dua in visibleDuas) ...[
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
