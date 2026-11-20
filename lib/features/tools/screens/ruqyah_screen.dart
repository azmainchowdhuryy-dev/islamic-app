import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';

class _RuqyahPassage {
  final String titleBn;
  final String titleEn;
  final String arabic;
  final String meaningBn;
  final String meaningEn;
  final String reference;

  const _RuqyahPassage({
    required this.titleBn,
    required this.titleEn,
    required this.arabic,
    required this.meaningBn,
    required this.meaningEn,
    required this.reference,
  });
}

const _passages = <_RuqyahPassage>[
  _RuqyahPassage(
    titleBn: 'সূরা আল-ফাতিহা',
    titleEn: 'Surah Al-Fatihah',
    arabic: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ الرَّحْمَٰنِ الرَّحِيمِ مَالِكِ يَوْمِ الدِّينِ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
    meaningBn: 'আল্লাহর প্রশংসা, তাঁর ইবাদত, তাঁর সাহায্য প্রার্থনা এবং সরল পথের দোয়া এই সূরার মূল বিষয়।',
    meaningEn: 'This surah praises Allah and asks Him for help and guidance to the straight path.',
    reference: 'সূরা আল-ফাতিহা, ১:১–৭',
  ),
  _RuqyahPassage(
    titleBn: 'আয়াতুল কুরসি',
    titleEn: 'Ayat al-Kursi',
    arabic: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ وَلَا يَئُودُهُ حِفْظُهُمَا وَهُوَ الْعَلِيُّ الْعَظِيمُ',
    meaningBn: 'আল্লাহ এক, চিরঞ্জীব ও সবকিছুর ধারক। আসমান-জমিনের সবকিছু তাঁর। তাঁর জ্ঞান ও ক্ষমতা সবকিছুকে পরিবেষ্টন করে আছে।',
    meaningEn: 'Allah is the One, the Ever-Living and Sustainer. Everything in the heavens and earth belongs to Him, and His knowledge encompasses all things.',
    reference: 'সূরা আল-বাকারা, ২:২৫৫',
  ),
  _RuqyahPassage(
    titleBn: 'সূরা আল-ইখলাস',
    titleEn: 'Surah Al-Ikhlas',
    arabic: 'قُلْ هُوَ اللَّهُ أَحَدٌ اللَّهُ الصَّمَدُ لَمْ يَلِدْ وَلَمْ يُولَدْ وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ',
    meaningBn: 'বলুন, তিনি আল্লাহ, এক। আল্লাহ অমুখাপেক্ষী। তিনি কাউকে জন্ম দেননি এবং তাঁকেও জন্ম দেওয়া হয়নি। তাঁর সমতুল্য কেউ নেই।',
    meaningEn: 'Allah is One and Self-Sufficient. He neither begets nor is born, and nothing is comparable to Him.',
    reference: 'সূরা আল-ইখলাস, ১১২:১–৪',
  ),
  _RuqyahPassage(
    titleBn: 'সূরা আল-ফালাক',
    titleEn: 'Surah Al-Falaq',
    arabic: 'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ مِنْ شَرِّ مَا خَلَقَ وَمِنْ شَرِّ غَاسِقٍ إِذَا وَقَبَ وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ وَمِنْ شَرِّ حَاسِدٍ إِذَا حَسَدَ',
    meaningBn: 'সৃষ্টির অনিষ্ট, অন্ধকারের অনিষ্ট, গিঁটে ফুঁদানকারীদের অনিষ্ট এবং হিংসুকের অনিষ্ট থেকে আল্লাহর আশ্রয় চাওয়া হয়েছে।',
    meaningEn: 'This surah seeks Allah’s protection from the harm of creation, darkness, sorcery and envy.',
    reference: 'সূরা আল-ফালাক, ১১৩:১–৫',
  ),
  _RuqyahPassage(
    titleBn: 'সূরা আন-নাস',
    titleEn: 'Surah An-Nas',
    arabic: 'قُلْ أَعُوذُ بِرَبِّ النَّاسِ مَلِكِ النَّاسِ إِلَٰهِ النَّاسِ مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ مِنَ الْجِنَّةِ وَالنَّاسِ',
    meaningBn: 'মানুষের রব, অধিপতি ও উপাস্যের কাছে অন্তরের কুমন্ত্রণা এবং জিন ও মানুষের অনিষ্ট থেকে আশ্রয় চাওয়া হয়েছে।',
    meaningEn: 'This surah seeks protection from the whispering evil that affects people, from jinn and humans.',
    reference: 'সূরা আন-নাস, ১১৪:১–৬',
  ),
];

class RuqyahScreen extends ConsumerWidget {
  const RuqyahScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(stringsProvider).lang == 'bn';
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(bn ? 'রুকইয়াহ' : 'Ruqyah')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                bn
                    ? 'রুকইয়াহ হলো কুরআনের আয়াত ও সহিহ দোয়ার মাধ্যমে আল্লাহর কাছে আশ্রয় ও আরোগ্য চাওয়া। নিচের আয়াতগুলো মনোযোগ দিয়ে পড়ুন।'
                    : 'Ruqyah is seeking Allah’s protection and healing through Quranic verses and authentic supplications. Recite the passages below attentively.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                  height: 1.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final item in _passages) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      bn ? item.titleBn : item.titleEn,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        item.arabic,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          height: 2,
                          fontFamily: 'serif',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      bn ? item.meaningBn : item.meaningEn,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.reference,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bn ? 'সুন্নাহর নির্দেশনা' : 'Practice from the Sunnah',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bn
                        ? 'আয়িশা (রা.) বর্ণনা করেন, রাসুলুল্লাহ (সা.) প্রতি রাতে ঘুমাতে যাওয়ার আগে সূরা ইখলাস, ফালাক ও নাস পড়ে দুই হাতের তালুতে ফুঁ দিতেন, তারপর শরীরের যতটুকু সম্ভব মুছে নিতেন। তিনি এটি তিনবার করতেন।'
                        : 'Aishah (ra) reported that before sleeping each night, the Messenger of Allah recited Al-Ikhlas, Al-Falaq and An-Nas into his cupped hands, blew gently and wiped over his body. He did this three times.',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bn ? 'সহিহ আল-বুখারি ৫০১৭' : 'Sahih al-Bukhari 5017',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Divider(height: 24),
                  Text(
                    bn
                        ? 'আয়িশা (রা.) আরও বর্ণনা করেন, পরিবারের কেউ অসুস্থ হলে রাসুলুল্লাহ (সা.) মু‘আওয়িযাত পড়ে তার ওপর ফুঁ দিতেন।'
                        : 'Aishah (ra) also reported that when a member of his household was ill, the Prophet recited the Mu‘awwidhat and blew over them.',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bn ? 'সহিহ মুসলিম ২১৯২a' : 'Sahih Muslim 2192a',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bn
                ? 'গুরুত্বপূর্ণ: রুকইয়াহ চিকিৎসার বিকল্প নয়। অসুস্থতা বা উপসর্গ থাকলে প্রয়োজনীয় চিকিৎসা নিন। অজানা মন্ত্র, তাবিজ বা শিরকযুক্ত পদ্ধতি থেকে দূরে থাকুন।'
                : 'Important: Ruqyah is not a substitute for medical care. Seek appropriate treatment for illness or symptoms. Avoid unknown incantations, amulets and practices involving shirk.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
