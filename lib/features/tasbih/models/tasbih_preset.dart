/// Built-in Tasbih choices shown in the selection bottom sheet.
class TasbihPreset {
  final String key;
  final String titleBn;
  final String titleEn;
  final String arabic;
  final int target;
  final String iconName;
  final bool requiresPremium;

  const TasbihPreset({
    required this.key,
    required this.titleBn,
    required this.titleEn,
    required this.arabic,
    required this.target,
    required this.iconName,
    this.requiresPremium = false,
  });

  String title(String language) => language == 'bn' ? titleBn : titleEn;
}

const List<TasbihPreset> tasbihPresets = [
  TasbihPreset(
    key: 'general',
    titleBn: 'সাধারণ',
    titleEn: 'General',
    arabic: '',
    target: 100,
    iconName: 'fingerprint',
  ),
  TasbihPreset(
    key: 'subhanallah',
    titleBn: 'সুবহানাল্লাহ',
    titleEn: 'SubhanAllah',
    arabic: 'سُبْحَانَ اللَّهِ',
    target: 33,
    iconName: 'sparkles',
  ),
  TasbihPreset(
    key: 'alhamdulillah',
    titleBn: 'আলহামদুলিল্লাহ',
    titleEn: 'Alhamdulillah',
    arabic: 'الْحَمْدُ لِلَّهِ',
    target: 33,
    iconName: 'favorite',
  ),
  TasbihPreset(
    key: 'allahu_akbar',
    titleBn: 'আল্লাহু আকবার',
    titleEn: 'Allahu Akbar',
    arabic: 'اللَّهُ أَكْبَرُ',
    target: 33,
    iconName: 'star',
  ),
  TasbihPreset(
    key: 'la_ilaha_illallah',
    titleBn: 'লা ইলাহা ইল্লাল্লাহ',
    titleEn: 'La ilaha illallah',
    arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ',
    target: 100,
    iconName: 'mosque',
  ),
  TasbihPreset(
    key: 'istighfar',
    titleBn: 'আস্তাগফিরুল্লাহ',
    titleEn: 'Astaghfirullah',
    arabic: 'أَسْتَغْفِرُ اللَّهَ',
    target: 100,
    iconName: 'self_improvement',
  ),
  TasbihPreset(
    key: 'subhanallah_bihamdihi',
    titleBn: 'সুবহানাল্লাহ ওয়া বিহামদিহি',
    titleEn: 'SubhanAllahi wa bihamdihi',
    arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    target: 100,
    iconName: 'spa',
  ),
  TasbihPreset(
    key: 'la_hawla',
    titleBn: 'লা হাওলা ওয়ালা কুওয়াতা',
    titleEn: 'La hawla wa la quwwata illa billah',
    arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    target: 33,
    iconName: 'all_inclusive',
  ),
  TasbihPreset(
    key: 'durood',
    titleBn: 'দরূদ শরীফ',
    titleEn: 'Durood Sharif',
    arabic: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ',
    target: 100,
    iconName: 'volunteer_activism',
  ),
];

TasbihPreset tasbihPresetForKey(String key) => tasbihPresets.firstWhere(
      (preset) => preset.key == key,
      orElse: () => tasbihPresets.first,
    );
