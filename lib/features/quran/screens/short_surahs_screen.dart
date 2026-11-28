import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

class ShortSurahVerse {
  const ShortSurahVerse({
    required this.number,
    required this.arabic,
    required this.translation,
    required this.translationNotes,
  });

  final int number;
  final String arabic;
  final String translation;
  final String translationNotes;

  factory ShortSurahVerse.fromJson(Map<String, dynamic> json) {
    return ShortSurahVerse(
      number: json['number'] as int,
      arabic: json['arabic'] as String,
      translation: json['translation'] as String,
      translationNotes: json['translation_notes'] as String? ?? '',
    );
  }
}

class ShortSurah {
  const ShortSurah({
    required this.number,
    required this.nameBn,
    required this.nameAr,
    required this.ayahCount,
    required this.verses,
  });

  final int number;
  final String nameBn;
  final String nameAr;
  final int ayahCount;
  final List<ShortSurahVerse> verses;

  factory ShortSurah.fromJson(Map<String, dynamic> json) {
    final verses = (json['verses'] as List<dynamic>)
        .map((item) => ShortSurahVerse.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    if (verses.length != json['ayah_count'] ||
        verses.asMap().entries.any((entry) => entry.value.number != entry.key + 1)) {
      throw FormatException('Invalid ayah sequence for surah ${json['number']}');
    }
    return ShortSurah(
      number: json['number'] as int,
      nameBn: json['name_bn'] as String,
      nameAr: json['name_ar'] as String,
      ayahCount: json['ayah_count'] as int,
      verses: verses,
    );
  }
}

Future<List<ShortSurah>> loadShortSurahs() async {
  final raw = await rootBundle.loadString('assets/data/short_surahs.json');
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final surahs = (decoded['surahs'] as List<dynamic>)
      .map((item) => ShortSurah.fromJson(item as Map<String, dynamic>))
      .toList(growable: false);
  const expectedAyahCounts = <int, int>{
    1: 7,
    100: 11,
    101: 11,
    102: 8,
    103: 3,
    104: 9,
    105: 5,
    106: 4,
    107: 7,
    108: 3,
    109: 6,
    110: 3,
    111: 5,
    112: 4,
    113: 5,
    114: 6,
  };
  final expectedNumbers = expectedAyahCounts.keys.toList(growable: false);
  if (surahs.length != expectedNumbers.length) {
    throw const FormatException('Short surah dataset has an unexpected number of surahs.');
  }
  for (var index = 0; index < surahs.length; index++) {
    final surah = surahs[index];
    final expectedNumber = expectedNumbers[index];
    if (surah.number != expectedNumber ||
        surah.ayahCount != expectedAyahCounts[expectedNumber] ||
        surah.verses.any(
          (verse) => verse.arabic.trim().isEmpty || verse.translation.trim().isEmpty,
        )) {
      throw FormatException('Short surah dataset failed validation at surah $expectedNumber.');
    }
  }
  return surahs;
}

class ShortSurahsScreen extends StatelessWidget {
  const ShortSurahsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ছোট সূরা')),
      body: FutureBuilder<List<ShortSurah>>(
        future: loadShortSurahs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('সূরার তথ্য লোড করা যায়নি। আবার চেষ্টা করুন।'),
              ),
            );
          }
          final surahs = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'আরবি, আয়াতভিত্তিক বাংলা অর্থ',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'সূরা আল-ফাতিহাসহ ১৬টি সূরা। অফলাইনে পড়া যাবে।',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (final surah in surahs)
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      child: Text(surah.number.toString()),
                    ),
                    title: Text(
                      surah.nameBn,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('${surah.ayahCount} আয়াত'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          surah.nameAr,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ShortSurahDetailScreen(surah: surah),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              const _SourceAttribution(),
            ],
          );
        },
      ),
    );
  }
}

class ShortSurahDetailScreen extends StatelessWidget {
  const ShortSurahDetailScreen({super.key, required this.surah});

  final ShortSurah surah;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(surah.nameBn)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Text(
                    surah.nameAr,
                    textDirection: TextDirection.rtl,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${surah.ayahCount} আয়াত'),
                ],
              ),
            ),
          ),
          for (final verse in surah.verses)
            Card(
              margin: const EdgeInsets.only(top: 10),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          child: Text(
                            verse.number.toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'আয়াত ${verse.number}',
                          style: theme.textTheme.labelLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        verse.arabic,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          height: 2.0,
                          fontSize: 27,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'বাংলা অর্থ',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      verse.translation,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
                    ),
                    if (verse.translationNotes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        title: const Text('অনুবাদকের ব্যাখ্যা ও টীকা'),
                        children: [
                          SelectableText(
                            verse.translationNotes,
                            style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 14),
          const _PronunciationGuidance(),
          const SizedBox(height: 14),
          const _SourceAttribution(),
        ],
      ),
    );
  }
}

class _PronunciationGuidance extends StatelessWidget {
  const _PronunciationGuidance();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'উচ্চারণ ও মাখরাজের সহায়ক নির্দেশনা',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'বাংলা হরফে আরবি ধ্বনির সব পার্থক্য প্রকাশ করা যায় না। তাই যাচাইকৃত শিক্ষক-প্রস্তুত বাংলা উচ্চারণ যুক্ত না হওয়া পর্যন্ত অনুমানভিত্তিক উচ্চারণ দেখানো হচ্ছে না।',
            ),
            const SizedBox(height: 8),
            const Text('মাখরাজের সাধারণ স্মরণিকা:'),
            const SizedBox(height: 6),
            const _MakhrajReminderRow(
              arabicLetters: 'ء هـ ع ح غ خ',
              description: 'গলার বিভিন্ন স্থান থেকে উচ্চারিত হয়।',
            ),
            const _MakhrajReminderRow(
              arabicLetters: 'ق',
              description: 'জিহ্বার পেছন ও তালুর সংযোগস্থল থেকে উচ্চারিত হয়।',
            ),
            const _MakhrajReminderRow(
              arabicLetters: 'ف',
              description: 'নিচের ঠোঁট ও ওপরের দাঁতের সংযোগে উচ্চারিত হয়।',
            ),
            const _MakhrajReminderRow(
              arabicLetters: 'ب م',
              description: 'দুই ঠোঁটের সাহায্যে উচ্চারিত হয়।',
            ),
            const SizedBox(height: 8),
            Text(
              'শুদ্ধ তিলাওয়াত শেখার জন্য যোগ্য শিক্ষকের কাছে শুনে ও পড়ে সংশোধন করুন।',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MakhrajReminderRow extends StatelessWidget {
  const _MakhrajReminderRow({
    required this.arabicLetters,
    required this.description,
  });

  final String arabicLetters;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                arabicLetters,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceAttribution extends StatelessWidget {
  const _SourceAttribution();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.5,
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('তথ্যসূত্র ও স্বীকৃতি', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              'আরবি পাঠ: Tanzil Quran Text (Uthmani, Version 1.1). Copyright © 2007-2021 Tanzil Project. CC BY 3.0. পাঠ অপরিবর্তিত রাখা হয়েছে।',
              style: style,
            ),
            const SizedBox(height: 6),
            Text(
              'বাংলা অনুবাদ ও টীকা: ড. আবূ বকর মুহাম্মাদ যাকারিয়া, সংস্করণ 1.1.1, QuranEnc.com. অনুবাদ ও টীকা অপরিবর্তিত রাখা হয়েছে।',
              style: style,
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: const Text('Tanzil-এর সম্পূর্ণ কপিরাইট ও ব্যবহারের শর্ত'),
              children: const [
                SelectableText(
                  'Tanzil Quran Text (Uthmani, Version 1.1)\\n'
                  'Copyright (C) 2007-2021 Tanzil Project\\n'
                  'License: Creative Commons Attribution 3.0\\n\\n'
                  'This copy of the Quran text is carefully produced, highly '
                  'verified and continuously monitored by a group of specialists '
                  'in Tanzil Project.\\n\\n'
                  'TERMS OF USE:\\n'
                  '- Permission is granted to copy and distribute verbatim copies '
                  'of this text, but CHANGING IT IS NOT ALLOWED.\\n'
                  '- This Quran text can be used in any website or application, '
                  'provided that its source (Tanzil Project) is clearly indicated, '
                  'and a link is made to tanzil.net to enable users to keep track '
                  'of changes.\\n'
                  '- This copyright notice shall be included in all verbatim '
                  'copies of the text, and shall be reproduced appropriately in '
                  'all files derived from or containing substantial portion of '
                  'this text.\\n'
                  'Please check updates at: http://tanzil.net/updates/',
                  style: TextStyle(height: 1.5),
                ),
              ],
            ),
            const Text(
              'QuranEnc-এর শর্ত: অনুবাদ ও টীকা অপরিবর্তিত রাখা, প্রকাশক ও সংস্করণ উল্লেখ, উৎসের সর্বশেষ সংস্করণ অনুসরণ এবং অনুপযুক্ত বিজ্ঞাপন পরিহার।',
            ),
            const SizedBox(height: 8),
            const SelectableText('https://tanzil.net'),
            const SelectableText('https://quranenc.com/bn/browse/bengali_zakaria'),
          ],
        ),
      ),
    );
  }
}
