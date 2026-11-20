import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/navigation/navigation_provider.dart';
import '../../hadith/screens/hadith_dua_screen.dart';
import '../../settings/screens/ibadah_tools_screen.dart';
import '../../tasbih/screens/tasbih_screen.dart';
import 'qibla_screen.dart';
import 'ruqyah_screen.dart';

class FeaturesScreen extends ConsumerWidget {
  const FeaturesScreen({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      );

  Widget _featureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: tint.withValues(alpha: .10),
                child: Icon(icon, color: tint),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final bn = strings.lang == 'bn';

    return Scaffold(
      appBar: AppBar(title: Text(bn ? 'সব ফিচার' : 'All Features')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 34,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    bn
                        ? 'ইবাদত, যিকির ও দৈনন্দিন ইসলামী প্রয়োজনের সব টুল এক জায়গায়'
                        : 'Daily worship, remembrance and Islamic tools in one place',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
          _sectionTitle(context, bn ? 'ট্র্যাকার' : 'Trackers'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.25,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _featureCard(
                context: context,
                icon: Icons.mosque_outlined,
                title: bn ? 'আজকের নামাজ' : 'Prayer Tracker',
                description: bn ? 'পাঁচ ওয়াক্তের হিসাব রাখুন' : 'Track your five daily prayers',
                onTap: () => _open(context, const IbadahToolsScreen()),
              ),
              _featureCard(
                context: context,
                icon: Icons.checklist_rtl,
                title: bn ? 'দৈনিক আমল' : 'Daily Amal',
                description: bn ? 'প্রতিদিনের ভালো কাজের তালিকা' : 'Keep a daily good-deeds checklist',
                onTap: () => _open(context, const IbadahToolsScreen()),
              ),
            ],
          ),
          _sectionTitle(context, bn ? 'ইসলামী টুলস' : 'Islamic Tools'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.25,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _featureCard(
                context: context,
                icon: Icons.explore_outlined,
                title: bn ? 'কিবলা' : 'Qibla',
                description: bn ? 'কাবার দিক নির্ণয় করুন' : 'Find the direction of the Kaaba',
                onTap: () => _open(context, const QiblaScreen()),
              ),
              _featureCard(
                context: context,
                icon: Icons.menu_book_outlined,
                title: bn ? 'রুকইয়াহ' : 'Ruqyah',
                description: bn ? 'কুরআনের আয়াত ও সহিহ সুন্নাহ' : 'Quranic recitations and authentic Sunnah',
                onTap: () => _open(context, const RuqyahScreen()),
              ),
              _featureCard(
                context: context,
                icon: Icons.favorite_outline,
                title: bn ? 'আল্লাহর ৯৯ নাম' : '99 Names of Allah',
                description: bn ? 'আরবি, উচ্চারণ ও অর্থ' : 'Arabic, transliteration and meanings',
                onTap: () => _open(context, const IbadahToolsScreen()),
              ),
              _featureCard(
                context: context,
                icon: Icons.fingerprint,
                title: bn ? 'তাসবিহ' : 'Tasbih',
                description: bn ? 'ডিজিটাল যিকির কাউন্টার' : 'Digital dhikr counter',
                onTap: () => _open(context, const TasbihScreen()),
              ),
            ],
          ),
          _sectionTitle(context, bn ? 'জ্ঞান ও দোয়া' : 'Knowledge and Duas'),
          _featureCard(
            context: context,
            icon: Icons.menu_book,
            title: bn ? 'হাদিস ও দোয়া' : 'Hadith and Dua',
            description: bn ? 'বিষয়ভিত্তিক হাদিস ও কুরআনের দোয়া' : 'Browse hadith and Quranic duas by topic',
            onTap: () => ref.read(mainNavigationIndexProvider.notifier).state = 1,
          ),
        ],
      ),
    );
  }
}
