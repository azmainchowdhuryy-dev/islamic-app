import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/services/prefs.dart';

class _Name {
  final int number;
  final String arabic, transliteration, bn, en;
  const _Name(this.number, this.arabic, this.transliteration, this.bn, this.en);
}

const _names = <_Name>[
  _Name(1,'اللَّهُ','Allah','আল্লাহ','Allah'),
  _Name(2,'الرَّحْمَٰنُ','Ar-Rahman','পরম করুণাময়','The Most Compassionate'),
  _Name(3,'الرَّحِيمُ','Ar-Raheem','অতি দয়ালু','The Most Merciful'),
  _Name(4,'الْمَلِكُ','Al-Malik','সর্বময় অধিপতি','The King'),
  _Name(5,'الْقُدُّوسُ','Al-Quddus','পবিত্রতম','The Most Holy'),
  _Name(6,'السَّلَامُ','As-Salam','শান্তি ও নিরাপত্তার উৎস','The Source of Peace'),
  _Name(7,'الْمُؤْمِنُ','Al-Mumin','নিরাপত্তা দানকারী','The Giver of Security'),
  _Name(8,'الْمُهَيْمِنُ','Al-Muhaymin','সর্বতত্ত্বাবধায়ক','The Guardian'),
  _Name(9,'الْعَزِيزُ','Al-Aziz','মহাপরাক্রমশালী','The Almighty'),
  _Name(10,'الْجَبَّارُ','Al-Jabbar','মহাপ্রতাপশালী','The Compeller'),
  _Name(11,'الْمُتَكَبِّرُ','Al-Mutakabbir','সুমহান','The Supreme'),
  _Name(12,'الْخَالِقُ','Al-Khaliq','সৃষ্টিকর্তা','The Creator'),
  _Name(13,'الْبَارِئُ','Al-Bari','উদ্ভাবনকারী','The Originator'),
  _Name(14,'الْمُصَوِّرُ','Al-Musawwir','আকৃতি দানকারী','The Fashioner'),
  _Name(15,'الْغَفَّارُ','Al-Ghaffar','বারবার ক্ষমাকারী','The All-Forgiving'),
  _Name(16,'الْقَهَّارُ','Al-Qahhar','প্রবল পরাক্রমশালী','The Subduer'),
  _Name(17,'الْوَهَّابُ','Al-Wahhab','মহাদাতা','The Bestower'),
  _Name(18,'الرَّزَّاقُ','Ar-Razzaq','রিজিকদাতা','The Provider'),
  _Name(19,'الْفَتَّاحُ','Al-Fattah','উন্মুক্তকারী ও ফয়সালাকারী','The Opener'),
  _Name(20,'الْعَلِيمُ','Al-Alim','সর্বজ্ঞ','The All-Knowing'),
  _Name(21,'الْقَابِضُ','Al-Qabid','সংকুচিতকারী','The Withholder'),
  _Name(22,'الْبَاسِطُ','Al-Basit','প্রশস্তকারী','The Expander'),
  _Name(23,'الْخَافِضُ','Al-Khafid','অবনতকারী','The Abaser'),
  _Name(24,'الرَّافِعُ','Ar-Rafi','উন্নতকারী','The Exalter'),
  _Name(25,'الْمُعِزُّ','Al-Muizz','সম্মানদাতা','The Honorer'),
  _Name(26,'الْمُذِلُّ','Al-Mudhill','অপমানিতকারী','The Humiliator'),
  _Name(27,'السَّمِيعُ','As-Sami','সর্বশ্রোতা','The All-Hearing'),
  _Name(28,'الْبَصِيرُ','Al-Basir','সর্বদ্রষ্টা','The All-Seeing'),
  _Name(29,'الْحَكَمُ','Al-Hakam','বিচারক','The Judge'),
  _Name(30,'الْعَدْلُ','Al-Adl','পরিপূর্ণ ন্যায়বিচারক','The Just'),
  _Name(31,'اللَّطِيفُ','Al-Latif','সূক্ষ্মদর্শী ও অনুগ্রহশীল','The Subtle'),
  _Name(32,'الْخَبِيرُ','Al-Khabir','সর্ববিষয়ে অবহিত','The All-Aware'),
  _Name(33,'الْحَلِيمُ','Al-Halim','পরম সহনশীল','The Forbearing'),
  _Name(34,'الْعَظِيمُ','Al-Azim','মহামহিমান্বিত','The Magnificent'),
  _Name(35,'الْغَفُورُ','Al-Ghafur','পরম ক্ষমাশীল','The Forgiving'),
  _Name(36,'الشَّكُورُ','Ash-Shakur','গুণগ্রাহী','The Appreciative'),
  _Name(37,'الْعَلِيُّ','Al-Ali','সুউচ্চ','The Most High'),
  _Name(38,'الْكَبِيرُ','Al-Kabir','সুমহান','The Most Great'),
  _Name(39,'الْحَفِيظُ','Al-Hafiz','সংরক্ষণকারী','The Preserver'),
  _Name(40,'الْمُقِيتُ','Al-Muqit','জীবনোপকরণ দানকারী','The Sustainer'),
  _Name(41,'الْحَسِيبُ','Al-Hasib','হিসাব গ্রহণকারী','The Reckoner'),
  _Name(42,'الْجَلِيلُ','Al-Jalil','মহিমান্বিত','The Majestic'),
  _Name(43,'الْكَرِيمُ','Al-Karim','মহানুভব','The Generous'),
  _Name(44,'الرَّقِيبُ','Ar-Raqib','সর্বক্ষণ পর্যবেক্ষক','The Watchful'),
  _Name(45,'الْمُجِيبُ','Al-Mujib','দোয়া কবুলকারী','The Responsive'),
  _Name(46,'الْوَاسِعُ','Al-Wasi','অসীম প্রাচুর্যের অধিকারী','The All-Encompassing'),
  _Name(47,'الْحَكِيمُ','Al-Hakim','প্রজ্ঞাময়','The All-Wise'),
  _Name(48,'الْوَدُودُ','Al-Wadud','পরম স্নেহশীল','The Most Loving'),
  _Name(49,'الْمَجِيدُ','Al-Majid','মহাগৌরবময়','The Glorious'),
  _Name(50,'الْبَاعِثُ','Al-Baith','পুনরুত্থানকারী','The Resurrector'),
  _Name(51,'الشَّهِيدُ','Ash-Shahid','সর্বসাক্ষী','The Witness'),
  _Name(52,'الْحَقُّ','Al-Haqq','চিরসত্য','The Truth'),
  _Name(53,'الْوَكِيلُ','Al-Wakil','পরম নির্ভরযোগ্য কর্মবিধায়ক','The Trustee'),
  _Name(54,'الْقَوِيُّ','Al-Qawiyy','পরম শক্তিধর','The All-Strong'),
  _Name(55,'الْمَتِينُ','Al-Matin','সুদৃঢ়','The Firm'),
  _Name(56,'الْوَلِيُّ','Al-Waliyy','অভিভাবক ও সাহায্যকারী','The Protecting Friend'),
  _Name(57,'الْحَمِيدُ','Al-Hamid','সকল প্রশংসার অধিকারী','The Praiseworthy'),
  _Name(58,'الْمُحْصِي','Al-Muhsi','সবকিছুর হিসাব সংরক্ষণকারী','The Accounter'),
  _Name(59,'الْمُبْدِئُ','Al-Mubdi','প্রথমবার সৃষ্টিকারী','The Originator'),
  _Name(60,'الْمُعِيدُ','Al-Muid','পুনরায় সৃষ্টিকারী','The Restorer'),
  _Name(61,'الْمُحْيِي','Al-Muhyi','জীবনদানকারী','The Giver of Life'),
  _Name(62,'الْمُمِيتُ','Al-Mumit','মৃত্যুদানকারী','The Bringer of Death'),
  _Name(63,'الْحَيُّ','Al-Hayy','চিরঞ্জীব','The Ever-Living'),
  _Name(64,'الْقَيُّومُ','Al-Qayyum','সর্বসত্তার ধারক','The Self-Subsisting'),
  _Name(65,'الْوَاجِدُ','Al-Wajid','অভাবমুক্ত','The Finder'),
  _Name(66,'الْمَاجِدُ','Al-Majid','মহামর্যাদাশীল','The Noble'),
  _Name(67,'الْوَاحِدُ','Al-Wahid','এক ও অদ্বিতীয়','The One'),
  _Name(68,'الصَّمَدُ','As-Samad','অমুখাপেক্ষী','The Eternal Refuge'),
  _Name(69,'الْقَادِرُ','Al-Qadir','সর্বক্ষমতাবান','The All-Powerful'),
  _Name(70,'الْمُقْتَدِرُ','Al-Muqtadir','পূর্ণ ক্ষমতার অধিকারী','The Omnipotent'),
  _Name(71,'الْمُقَدِّمُ','Al-Muqaddim','অগ্রসরকারী','The Expediter'),
  _Name(72,'الْمُؤَخِّرُ','Al-Muakhkhir','পিছিয়ে দানকারী','The Delayer'),
  _Name(73,'الْأَوَّلُ','Al-Awwal','অনাদি','The First'),
  _Name(74,'الْآخِرُ','Al-Akhir','অনন্ত','The Last'),
  _Name(75,'الظَّاهِرُ','Az-Zahir','প্রকাশ্য','The Manifest'),
  _Name(76,'الْبَاطِنُ','Al-Batin','অপ্রকাশ্য','The Hidden'),
  _Name(77,'الْوَالِي','Al-Wali','সর্বময় কর্তৃত্বশীল','The Governor'),
  _Name(78,'الْمُتَعَالِي','Al-Mutaali','সবার ঊর্ধ্বে','The Most Exalted'),
  _Name(79,'الْبَرُّ','Al-Barr','পরম কল্যাণকারী','The Source of Goodness'),
  _Name(80,'التَّوَّابُ','At-Tawwab','তওবা কবুলকারী','The Accepter of Repentance'),
  _Name(81,'الْمُنْتَقِمُ','Al-Muntaqim','ন্যায়সঙ্গত প্রতিফলদাতা','The Avenger'),
  _Name(82,'الْعَفُوُّ','Al-Afuww','পাপ মোচনকারী','The Pardoner'),
  _Name(83,'الرَّؤُوفُ','Ar-Rauf','পরম স্নেহশীল','The Most Kind'),
  _Name(84,'مَالِكُ الْمُلْكِ','Malik-ul-Mulk','সমগ্র রাজত্বের মালিক','Owner of Sovereignty'),
  _Name(85,'ذُو الْجَلَالِ وَالْإِكْرَامِ','Dhul-Jalali wal-Ikram','মহিমা ও সম্মানের অধিকারী','Lord of Majesty and Honor'),
  _Name(86,'الْمُقْسِطُ','Al-Muqsit','ন্যায় প্রতিষ্ঠাকারী','The Equitable'),
  _Name(87,'الْجَامِعُ','Al-Jami','একত্রকারী','The Gatherer'),
  _Name(88,'الْغَنِيُّ','Al-Ghani','অভাবমুক্ত ও অমুখাপেক্ষী','The Self-Sufficient'),
  _Name(89,'الْمُغْنِي','Al-Mughni','অভাবমোচনকারী','The Enricher'),
  _Name(90,'الْمَانِعُ','Al-Mani','নিবারণকারী','The Preventer'),
  _Name(91,'الضَّارُّ','Ad-Darr','ক্ষতি সংঘটনের ক্ষমতার অধিকারী','The Distresser'),
  _Name(92,'النَّافِعُ','An-Nafi','উপকারকারী','The Benefactor'),
  _Name(93,'النُّورُ','An-Nur','আলো','The Light'),
  _Name(94,'الْهَادِي','Al-Hadi','পথপ্রদর্শক','The Guide'),
  _Name(95,'الْبَدِيعُ','Al-Badi','অতুলনীয় স্রষ্টা','The Incomparable Originator'),
  _Name(96,'الْبَاقِي','Al-Baqi','চিরস্থায়ী','The Everlasting'),
  _Name(97,'الْوَارِثُ','Al-Warith','চূড়ান্ত উত্তরাধিকারী','The Inheritor'),
  _Name(98,'الرَّشِيدُ','Ar-Rashid','সঠিক পথপ্রদর্শক','The Guide to the Right Path'),
  _Name(99,'الصَّبُورُ','As-Sabur','অসীম ধৈর্যশীল','The Patient'),
];

const _prayers = [
  ('fajr','ফজর','Fajr'),
  ('dhuhr','যোহর','Dhuhr'),
  ('asr','আসর','Asr'),
  ('maghrib','মাগরিব','Maghrib'),
  ('isha','এশা','Isha'),
];

const _dailyAmal = [
  ('quran','কুরআন তিলাওয়াত','Read the Quran'),
  ('morning','সকালের যিকির','Morning adhkar'),
  ('evening','সন্ধ্যার যিকির','Evening adhkar'),
  ('charity','সদকা','Give charity'),
  ('parents','মা-বাবার খেদমত','Care for parents'),
  ('istighfar','ইস্তিগফার','Seek forgiveness'),
];

enum IbadahToolsSection { all, prayers, dailyAmal, names }

class IbadahToolsScreen extends ConsumerStatefulWidget {
  final IbadahToolsSection section;

  const IbadahToolsScreen({
    super.key,
    this.section = IbadahToolsSection.all,
  });

  @override
  ConsumerState<IbadahToolsScreen> createState() => _IbadahToolsScreenState();
}

class _IbadahToolsScreenState extends ConsumerState<IbadahToolsScreen> {
  String _query = '';
  String _dateKey = '';
  Timer? _dayWatcher;
  Future<void> _preferenceWriteQueue = Future<void>.value();
  Set<String> _donePrayers = {};
  Set<String> _doneAmal = {};
  Set<int> _favorites = {};

  @override
  void initState() {
    super.initState();
    _dateKey = _makeDateKey(DateTime.now());
    _load();
    _dayWatcher = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshForNewDay(),
    );
  }

  String _makeDateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void _refreshForNewDay() {
    if (!mounted) return;
    final nextDateKey = _makeDateKey(DateTime.now());
    if (nextDateKey == _dateKey) return;
    setState(() {
      _dateKey = nextDateKey;
      _donePrayers = {};
      _doneAmal = {};
    });
    _load();
  }

  @override
  void dispose() {
    _dayWatcher?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final dateKey = _dateKey;
    final p = ref.read(sharedPrefsProvider);
    if (!mounted) return;
    final validPrayerKeys = _prayers.map((item) => item.$1).toSet();
    final validAmalKeys = _dailyAmal.map((item) => item.$1).toSet();
    final savedFavorites = p.getStringList('asma_favorites') ?? [];
    if (!mounted || dateKey != _dateKey) return;
    setState(() {
      _donePrayers = (p.getStringList('prayer_tracker_$dateKey') ?? [])
          .where(validPrayerKeys.contains)
          .toSet();
      _doneAmal = (p.getStringList('daily_amal_$dateKey') ?? [])
          .where(validAmalKeys.contains)
          .toSet();
      _favorites = savedFavorites
          .map((value) => int.tryParse(value))
          .whereType<int>()
          .where((number) => number >= 1 && number <= 99)
          .toSet();
    });
  }

  Future<void> _saveStringList(String key, List<String> values) async {
    final prefs = ref.read(sharedPrefsProvider);
    final write = _preferenceWriteQueue
        .catchError((_) {})
        .then<void>((_) async {
          await prefs.setStringList(key, values);
        });
    _preferenceWriteQueue = write;
    await write;
  }

  Future<void> _toggle(String key, String prefKey) async {
    final current = prefKey.startsWith('prayer') ? _donePrayers : _doneAmal;
    final next = Set<String>.from(current);
    if (!next.add(key)) next.remove(key);
    setState(() {
      if (prefKey.startsWith('prayer')) {
        _donePrayers = next;
      } else {
        _doneAmal = next;
      }
    });
    try {
      await _saveStringList(prefKey, next.toList());
    } catch (_) {
      // Keep the updated checklist visible if local storage is temporarily unavailable.
    }
  }

  Future<void> _toggleFavorite(int number) async {
    final next = Set<int>.from(_favorites);
    if (!next.add(number)) next.remove(number);
    setState(() => _favorites = next);
    try {
      await _saveStringList(
        'asma_favorites',
        next.map((e) => e.toString()).toList(),
      );
    } catch (_) {
      // Keep the current screen responsive if local storage is temporarily unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(stringsProvider).lang;
    final theme = Theme.of(context);
    final showPrayers = widget.section == IbadahToolsSection.all ||
        widget.section == IbadahToolsSection.prayers;
    final showDailyAmal = widget.section == IbadahToolsSection.all ||
        widget.section == IbadahToolsSection.dailyAmal ||
        widget.section == IbadahToolsSection.prayers;
    final showNames = widget.section == IbadahToolsSection.all ||
        widget.section == IbadahToolsSection.names;
    final screenTitle = widget.section == IbadahToolsSection.prayers
        ? (lang == 'bn' ? 'ইবাদত ট্র্যাকার' : 'Worship Tracker')
        : widget.section == IbadahToolsSection.dailyAmal
            ? (lang == 'bn' ? 'দৈনিক আমল' : 'Daily Amal')
            : widget.section == IbadahToolsSection.names
                ? (lang == 'bn' ? 'আল্লাহর ৯৯ নাম' : '99 Names of Allah')
                : (lang == 'bn' ? 'ইবাদত ও আল্লাহর নাম' : 'Worship & Names of Allah');
    final visible = _names.where((n) {
      final q = _query.toLowerCase();
      return q.isEmpty || n.transliteration.toLowerCase().contains(q) ||
          n.arabic.contains(_query) || n.bn.contains(_query) || n.en.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(screenTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (showPrayers) Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(lang == 'bn' ? 'পাঁচ ওয়াক্ত নামাজের হিসাব' : 'Daily Prayer Tracker',
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(lang == 'bn'
                    ? '${_donePrayers.length} / 5 ওয়াক্ত আদায় হয়েছে'
                    : '${_donePrayers.length} / 5 prayers completed'),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: _donePrayers.length / 5),
                for (final p in _prayers)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: _donePrayers.contains(p.$1),
                    title: Text(lang == 'bn' ? p.$2 : p.$3),
                    onChanged: (_) => _toggle(p.$1, 'prayer_tracker_$_dateKey'),
                  ),
                Text(lang == 'bn'
                    ? 'এটি ব্যক্তিগত হিসাব রাখার সুবিধা, নামাজের সময়সূচি নয়।'
                    : 'This is a personal completion log, not a prayer-time schedule.',
                    style: theme.textTheme.bodySmall),
              ]),
            ),
          ),
          if (showDailyAmal) const SizedBox(height: 12),
          if (showDailyAmal) Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(lang == 'bn' ? 'আজকের আমলের তালিকা' : 'Today’s Amal Checklist',
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(lang == 'bn'
                    ? '${_doneAmal.length} / ${_dailyAmal.length} আমল সম্পন্ন'
                    : '${_doneAmal.length} / ${_dailyAmal.length} completed'),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: _doneAmal.length / _dailyAmal.length),
                for (final a in _dailyAmal)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: _doneAmal.contains(a.$1),
                    title: Text(lang == 'bn' ? a.$2 : a.$3),
                    onChanged: (_) => _toggle(a.$1, 'daily_amal_$_dateKey'),
                  ),
                Text(lang == 'bn'
                    ? 'প্রতিদিন নতুন তালিকা শুরু হবে।'
                    : 'A fresh checklist starts each day.',
                    style: theme.textTheme.bodySmall),
              ]),
            ),
          ),
          if (showNames) const SizedBox(height: 12),
          if (showNames) Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(lang == 'bn' ? 'আল্লাহর সুন্দর নামসমূহ' : '99 Names of Allah',
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(lang == 'bn'
                    ? 'কুরআন ও সুন্নাহভিত্তিক বহুল প্রচলিত সংকলন'
                    : 'A widely used compilation based on Quran and Sunnah'),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: lang == 'bn' ? 'নাম বা অর্থ খুঁজুন' : 'Search name or meaning',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 8),
                Text(lang == 'bn'
                    ? 'দ্রষ্টব্য: ৯৯ নামের মূল হাদিস সহিহ। প্রচলিত নির্দিষ্ট তালিকাটির বর্ণনা নিয়ে মুহাদ্দিসদের আলোচনা আছে।'
                    : 'Note: The hadith affirming 99 names is authentic. Scholars have discussed the specific commonly circulated enumeration.',
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                Text(lang == 'bn'
                    ? 'দেখানো হচ্ছে ${visible.length} / 99'
                    : 'Showing ${visible.length} / 99'),
                for (final n in visible)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text(n.number.toString())),
                    title: Text(n.arabic,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 24, height: 1.7)),
                    subtitle: Text('${n.transliteration} • ${lang == 'bn' ? n.bn : n.en}'),
                    trailing: IconButton(
                      tooltip: lang == 'bn' ? 'প্রিয় তালিকায় রাখুন' : 'Save favorite',
                      icon: Icon(_favorites.contains(n.number) ? Icons.favorite : Icons.favorite_border),
                      onPressed: () => _toggleFavorite(n.number),
                    ),
                  ),
              ]),
            ),
          ),
          if (showNames) const SizedBox(height: 12),
          if (showNames) Text(
            lang == 'bn'
                ? 'তথ্যসূত্র: সূরা আল-আ‘রাফ ৭:১৮০, সূরা আল-হাশর ৫৯:২৪, সহিহ বুখারি ২৭৩৬। প্রচলিত ৯৯ নামের তালিকা জামি‘ আত-তিরমিজি ৩৫০৭-এর সংকলনের সঙ্গে মেলে, তবে তালিকার সনদ নিয়ে মতভেদ রয়েছে।'
                : 'References: Quran 7:180, 59:24 and Sahih al-Bukhari 2736. The customary enumeration follows Jami at-Tirmidhi 3507, whose list transmission has been discussed by hadith scholars.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
