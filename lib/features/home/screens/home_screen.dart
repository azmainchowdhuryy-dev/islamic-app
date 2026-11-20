import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bangla_utilities/bangla_utilities.dart';
import 'package:hijri_date_time/hijri_date_time.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/services/prefs.dart';
import '../../hadith/providers/hadith_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../services/prayer_calculator.dart';
import '../../../core/navigation/navigation_provider.dart';

class _City {
  final String id;
  final String nameBn;
  final String nameEn;
  final double lat;
  final double lng;

  const _City({
    required this.id,
    required this.nameBn,
    required this.nameEn,
    required this.lat,
    required this.lng,
  });

  factory _City.fromJson(Map<String, dynamic> json) => _City(
        id: json['id'] as String,
        nameBn: json['name_bn'] as String,
        nameEn: json['name_en'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );

  String name(String lang) => lang == 'bn' ? nameBn : nameEn;
}

final _citiesProvider = FutureProvider<List<_City>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/cities_bd.json');
  final data = jsonDecode(raw) as List<dynamic>;
  return data
      .map((item) => _City.fromJson(item as Map<String, dynamic>))
      .toList();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _cityId = 'dhaka';
  bool _hanafi = true;
  PrayerCalculation _method = PrayerCalculation.karachi;
  int _hijriOffset = 0;
  DateTime _now = DateTime.now();
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPrefsProvider);
    _cityId = prefs.getString('home_city') ?? 'dhaka';
    _hanafi = prefs.getBool('home_hanafi') ?? true;
    final methodIndex = (prefs.getInt('home_calc_method') ?? 0)
        .clamp(0, PrayerCalculation.values.length - 1).toInt();
    _method = PrayerCalculation.values[methodIndex];
    _hijriOffset = (prefs.getInt('hijri_offset') ?? 0).clamp(-1, 1).toInt();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _saveCity(String value) async {
    setState(() => _cityId = value);
    await ref.read(sharedPrefsProvider).setString('home_city', value);
  }

  Future<void> _saveAsr(bool value) async {
    setState(() => _hanafi = value);
    await ref.read(sharedPrefsProvider).setBool('home_hanafi', value);
  }

  Future<void> _saveMethod(PrayerCalculation value) async {
    setState(() => _method = value);
    await ref.read(sharedPrefsProvider).setInt('home_calc_method', value.index);
  }

  Future<void> _saveHijriOffset(int value) async {
    setState(() => _hijriOffset = value);
    await ref.read(sharedPrefsProvider).setInt('hijri_offset', value);
  }

  String _time(DateTime value, AppStrings s) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour < 12
        ? (s.lang == 'bn' ? 'পূর্বাহ্ণ' : 'AM')
        : (s.lang == 'bn' ? 'অপরাহ্ণ' : 'PM');
    return s.digits('$hour:$minute $suffix');
  }

  String _date(DateTime date, AppStrings s) {
    const weekdaysBn = ['সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার', 'শনিবার', 'রবিবার'];
    const weekdaysEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const monthsBn = ['জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'];
    const monthsEn = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final weekday = s.lang == 'bn' ? weekdaysBn[date.weekday - 1] : weekdaysEn[date.weekday - 1];
    final month = s.lang == 'bn' ? monthsBn[date.month - 1] : monthsEn[date.month - 1];
    return '$weekday, ${s.digits(date.day)} $month ${s.digits(date.year)}';
  }

  String _countdown(Duration duration, AppStrings s) {
    if (duration.isNegative) duration = Duration.zero;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${s.digits(hours.toString().padLeft(2, '0'))}:${s.digits(minutes.toString().padLeft(2, '0'))}:${s.digits(seconds.toString().padLeft(2, '0'))}';
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lang = s.lang;
    final citiesAsync = ref.watch(_citiesProvider);
    final hadithAsync = ref.watch(hadithListProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('greeting'), style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                segments: const [
                  ButtonSegment(value: 'bn', label: Text('বাংলা')),
                  ButtonSegment(value: 'en', label: Text('EN')),
                ],
                selected: {lang},
                onSelectionChanged: (value) =>
                    ref.read(settingsProvider.notifier).setLang(value.first),
              ),
            ),
          ),
        ],
      ),
      body: citiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(s.t('prayer_error'))),
        data: (cities) {
          final city = cities.firstWhere(
            (item) => item.id == _cityId,
            orElse: () => cities.first,
          );
          final prayers = DailyPrayerTimes.calculate(
            latitude: city.lat,
            longitude: city.lng,
            date: _now,
            hanafi: _hanafi,
            method: _method,
          );
          final todayEntries = prayers.entries();
          final nextDay = _now.add(const Duration(days: 1));
          final tomorrow = DailyPrayerTimes.calculate(
            latitude: city.lat,
            longitude: city.lng,
            date: nextDay,
            hanafi: _hanafi,
            method: _method,
          );
          final nextFajr = tomorrow.fajr;
          final upcoming = todayEntries.firstWhere(
            (entry) => entry.value.isAfter(_now),
            orElse: () => MapEntry('fajr', nextFajr),
          );
          final nextName = s.t(upcoming.key);
          final remaining = upcoming.value.difference(_now);
          final banglaDate = BanglaDate.fromDateTime(_now);
          const banglaMonthsEn = [
            'Boishakh', 'Joishtho', 'Asharh', 'Shrabon', 'Bhadro', 'Ashwin',
            'Kartik', 'Ogrohayon', 'Poush', 'Magh', 'Falgun', 'Choitro'
          ];
          const hijriMonthsBn = [
            'মুহাররম', 'সফর', 'রবিউল আউয়াল', 'রবিউস সানি', 'জমাদিউল আউয়াল',
            'জমাদিউস সানি', 'রজব', 'শাবান', 'রমজান', 'শাওয়াল',
            'জিলকদ', 'জিলহজ'
          ];
          const hijriMonthsEn = [
            'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani',
            'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', 'Shaban',
            'Ramadan', 'Shawwal', 'Dhul Qadah', 'Dhul Hijjah'
          ];
          final hijriDate = HijriDateTime.fromGregorian(
            DateTime(_now.year, _now.month, _now.day),
          ).add(Duration(days: _hijriOffset));
          final banglaDateLabel = lang == 'bn'
              ? '${banglaDate.weekday}, ${banglaDate.day} ${banglaDate.monthName} ${banglaDate.year}'
              : '${banglaDate.dayInt} ${banglaMonthsEn[banglaDate.monthInt - 1]} ${banglaDate.yearInt}';
          final hijriDateLabel = lang == 'bn'
              ? '${s.digits(hijriDate.day)} ${hijriMonthsBn[hijriDate.month - 1]} ${s.digits(hijriDate.year)} হিজরি'
              : '${hijriDate.day} ${hijriMonthsEn[hijriDate.month - 1]} ${hijriDate.year} AH';

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Row(
                children: [
                  Icon(Icons.location_on_outlined, color: scheme.primary, size: 19),
                  const SizedBox(width: 6),
                  Text(s.t('city'), style: theme.textTheme.labelLarge),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: city.id,
                        items: [
                          for (final item in cities)
                            DropdownMenuItem(value: item.id, child: Text(item.name(lang))),
                        ],
                        onChanged: (value) {
                          if (value != null) _saveCity(value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                clipBehavior: Clip.antiAlias,
                color: scheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_date(_now, s),
                          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onPrimary.withValues(alpha: .9))),
                      const SizedBox(height: 8),
                      Text(banglaDateLabel,
                          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onPrimary.withValues(alpha: .9))),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(child: Text(hijriDateLabel,
                              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onPrimary.withValues(alpha: .9)))),
                          PopupMenuButton<int>(
                            tooltip: s.t('hijri_adjustment'),
                            icon: Icon(Icons.calendar_month, color: scheme.onPrimary, size: 20),
                            initialValue: _hijriOffset,
                            onSelected: _saveHijriOffset,
                            itemBuilder: (context) => [
                              PopupMenuItem(value: -1, child: Text(s.t('hijri_minus_one'))),
                              PopupMenuItem(value: 0, child: Text(s.t('hijri_no_adjustment'))),
                              PopupMenuItem(value: 1, child: Text(s.t('hijri_plus_one'))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(s.t('next_prayer'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onPrimary.withValues(alpha: .9))),
                          const Spacer(),
                          Text('$nextName  ${_time(upcoming.value, s)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: scheme.onPrimary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.hourglass_bottom, color: scheme.onPrimary),
                          const SizedBox(width: 8),
                          Text(s.t('time_left'), style: TextStyle(color: scheme.onPrimary)),
                          const Spacer(),
                          Text(_countdown(remaining, s),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: scheme.onPrimary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: Text(s.t('prayer_times'),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                  PopupMenuButton<PrayerCalculation>(
                    tooltip: s.t('calculation_method'),
                    icon: const Icon(Icons.tune),
                    initialValue: _method,
                    onSelected: _saveMethod,
                    itemBuilder: (context) => [
                      PopupMenuItem(value: PrayerCalculation.karachi, child: Text(s.t('karachi'))),
                      PopupMenuItem(value: PrayerCalculation.muslimWorldLeague, child: Text(s.t('mwl'))),
                      PopupMenuItem(value: PrayerCalculation.egyptian, child: Text(s.t('egypt'))),
                      PopupMenuItem(value: PrayerCalculation.dubai, child: Text(s.t('dubai'))),
                    ],
                  ),
                ],
              ),
              Card(
                child: Column(
                  children: [
                    for (final entry in todayEntries)
                      ListTile(
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        dense: true,
                        leading: Icon(
                          entry.key == upcoming.key ? Icons.notifications_active : Icons.access_time,
                          color: entry.key == upcoming.key ? scheme.primary : scheme.onSurfaceVariant,
                        ),
                        title: Text(s.t(entry.key),
                            style: TextStyle(fontWeight: entry.key == upcoming.key ? FontWeight.bold : FontWeight.normal)),
                        trailing: Text(_time(entry.value, s),
                            style: TextStyle(
                              fontWeight: entry.key == upcoming.key ? FontWeight.bold : FontWeight.w500,
                              color: entry.key == upcoming.key ? scheme.primary : null,
                            )),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(s.t('asr_method'), style: theme.textTheme.bodyMedium),
                  const Spacer(),
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: true, label: Text(s.t('hanafi'))),
                      ButtonSegment(value: false, label: Text(s.t('shafi'))),
                    ],
                    selected: {_hanafi},
                    onSelectionChanged: (value) => _saveAsr(value.first),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(s.t('calculation_note'),
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              Text(s.t('daily_hadith'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              hadithAsync.when(
                loading: () => const Card(child: Padding(
                  padding: EdgeInsets.all(18), child: LinearProgressIndicator())),
                error: (error, stack) => Card(child: Padding(
                  padding: const EdgeInsets.all(16), child: Text(s.t('daily_hadith_empty')))),
                data: (list) {
                  final eligible = list.where((item) => item.verified && item.dailyEligible).toList();
                  if (eligible.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.menu_book_outlined, color: scheme.primary),
                            const SizedBox(width: 12),
                            Expanded(child: Text(s.t('daily_hadith_empty'))),
                          ],
                        ),
                      ),
                    );
                  }
                  final item = eligible[_now.day % eligible.length];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.arabicText.isNotEmpty)
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(item.arabicText,
                                  style: theme.textTheme.titleLarge, textAlign: TextAlign.right),
                            ),
                          if (item.arabicText.isNotEmpty) const SizedBox(height: 12),
                          Text(lang == 'bn' ? item.banglaTranslation : item.englishTranslation,
                              style: theme.textTheme.bodyLarge),
                          const SizedBox(height: 12),
                          Text('${s.t('source')}: ${item.source}  •  ${s.t('reference')}: ${item.reference}',
                              style: theme.textTheme.bodySmall),
                          if (item.grade.isNotEmpty)
                            Text(item.grade, style: theme.textTheme.labelSmall),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: scheme.primary, size: 26),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}
