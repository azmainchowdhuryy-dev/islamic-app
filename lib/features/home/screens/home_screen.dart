import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bangla_utilities/bangla_utilities.dart';
import 'package:hijri_date_time/hijri_date_time.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/navigation/navigation_provider.dart';
import '../../../core/services/prefs.dart';
import '../../hadith/providers/hadith_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../settings/screens/ibadah_tools_screen.dart';
import '../../tasbih/screens/tasbih_screen.dart';
import '../../tools/screens/ruqyah_screen.dart';
import '../services/daily_hadith_index.dart';
import '../services/prayer_calculator.dart';

class HomeCity {
  final String id;
  final String nameBn;
  final String nameEn;
  final double lat;
  final double lng;

  const HomeCity({
    required this.id,
    required this.nameBn,
    required this.nameEn,
    required this.lat,
    required this.lng,
  });

  factory HomeCity.fromJson(Map<String, dynamic> json) => HomeCity(
        id: json['id'] as String,
        nameBn: json['name_bn'] as String,
        nameEn: json['name_en'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );

  String name(String lang) => lang == 'bn' ? nameBn : nameEn;
}

final homeCitiesProvider = FutureProvider<List<HomeCity>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/cities_bd.json');
  final data = jsonDecode(raw) as List<dynamic>;
  return data
      .map((item) => HomeCity.fromJson(item as Map<String, dynamic>))
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

  Future<void> _togglePrayerFromHome(
    String key,
    Set<String> current,
    String dateKey,
  ) async {
    final next = Set<String>.from(current);
    if (!next.add(key)) next.remove(key);
    await ref
        .read(sharedPrefsProvider)
        .setStringList('prayer_tracker_$dateKey', next.toList());
    if (mounted) setState(() {});
  }

  String _clockTime(DateTime value, AppStrings s) {
    final hourValue = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final hour = hourValue.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return s.digits('$hour:$minute');
  }

  String _countdown(Duration duration, AppStrings s) {
    if (duration.isNegative) duration = Duration.zero;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${s.digits(hours.toString().padLeft(2, '0'))}:${s.digits(minutes.toString().padLeft(2, '0'))}:${s.digits(seconds.toString().padLeft(2, '0'))}';
  }

  Future<void> _openTool(BuildContext context, Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lang = s.lang;
    final citiesAsync = ref.watch(homeCitiesProvider);
    final hadithAsync = ref.watch(hadithListProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF101A1E),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF1B2529),
        body: citiesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text(s.t('prayer_error'),
                style: const TextStyle(color: Color(0xFFE6EEF0))),
          ),
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
            final tomorrow = DailyPrayerTimes.calculate(
              latitude: city.lat,
              longitude: city.lng,
              date: _now.add(const Duration(days: 1)),
              hanafi: _hanafi,
              method: _method,
            );
            final yesterday = DailyPrayerTimes.calculate(
              latitude: city.lat,
              longitude: city.lng,
              date: _now.subtract(const Duration(days: 1)),
              hanafi: _hanafi,
              method: _method,
            );
            final upcoming = todayEntries.firstWhere(
              (entry) => entry.value.isAfter(_now),
              orElse: () => MapEntry('fajr', tomorrow.fajr),
            );
            final nextName = s.t(upcoming.key);
            final remaining = upcoming.value.difference(_now);
            final isTomorrowFajr =
                !todayEntries.any((entry) => entry.value.isAfter(_now));
            final nextIndex = todayEntries.indexWhere(
              (entry) => entry.key == upcoming.key,
            );
            final previousPrayerTime = isTomorrowFajr
                ? todayEntries.last.value
                : nextIndex == 0
                    ? yesterday.isha
                    : todayEntries[nextIndex - 1].value;
            final intervalSeconds =
                upcoming.value.difference(previousPrayerTime).inSeconds;
            final elapsedSeconds = _now
                .difference(previousPrayerTime)
                .inSeconds
                .clamp(0, intervalSeconds > 0 ? intervalSeconds : 0);
            final countdownProgress = intervalSeconds > 0
                ? elapsedSeconds / intervalSeconds
                : 0.0;

            final banglaDate = BanglaDate.fromDateTime(_now);
            const banglaMonthsEn = [
              'Boishakh', 'Joishtho', 'Asharh', 'Shrabon', 'Bhadro', 'Ashwin',
              'Kartik', 'Ogrohayon', 'Poush', 'Magh', 'Falgun', 'Choitro'
            ];
            const gregorianMonthsBn = [
              'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
              'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
            ];
            const gregorianMonthsEn = [
              'January', 'February', 'March', 'April', 'May', 'June',
              'July', 'August', 'September', 'October', 'November', 'December'
            ];
            const weekdaysBn = [
              'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি', 'রবি'
            ];
            const weekdaysEn = [
              'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
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
            final weekdayLabel = lang == 'bn'
                ? weekdaysBn[_now.weekday - 1]
                : weekdaysEn[_now.weekday - 1];
            final hijriDateLabel = lang == 'bn'
                ? '$weekdayLabel, ${s.digits(hijriDate.day)} ${hijriMonthsBn[hijriDate.month - 1]}'
                : '$weekdayLabel, ${hijriDate.day} ${hijriMonthsEn[hijriDate.month - 1]}';
            final calendarDateLabel = lang == 'bn'
                ? '${s.digits(_now.day)} ${gregorianMonthsBn[_now.month - 1]}, ${s.digits(banglaDate.day)} ${banglaDate.monthName}'
                : '${_now.day} ${gregorianMonthsEn[_now.month - 1]}, ${banglaDate.dayInt} ${banglaMonthsEn[banglaDate.monthInt - 1]}';

            final todayKey =
                '${_now.year}-${_now.month.toString().padLeft(2, '0')}-${_now.day.toString().padLeft(2, '0')}';
            final todayPrefs = ref.read(sharedPrefsProvider);
            const validPrayerKeys = {'fajr', 'dhuhr', 'asr', 'maghrib', 'isha'};
            final prayerDoneKeys = (todayPrefs
                        .getStringList('prayer_tracker_$todayKey') ??
                    [])
                .where(validPrayerKeys.contains)
                .toSet();
            final prayerDone = prayerDoneKeys.length;
            final prayerPercent = (prayerDone / 5 * 100).round();

            return SafeArea(
              top: false,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFDDF3E5),
                          Color(0xFFCBEBD7),
                          Color(0xFFE8F7EC),
                        ],
                      ),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      MediaQuery.of(context).padding.top + 8,
                      16,
                      9,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined,
                                color: Color(0xFF252719), size: 27),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hijriDateLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF29291F),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    calendarDateLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF3B3A2E),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: const Color(0x55FFFFFF),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _LanguageChoice(
                                    label: 'বাংলা',
                                    selected: lang == 'bn',
                                    onTap: () => ref.read(settingsProvider.notifier).setLang('bn'),
                                  ),
                                  _LanguageChoice(
                                    label: 'EN',
                                    selected: lang == 'en',
                                    onTap: () => ref.read(settingsProvider.notifier).setLang('en'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 0),
                        SizedBox(
                          height: 154,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _PrayerCountdownArcPainter(
                                    progress: countdownProgress.toDouble(),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      nextName,
                                      style: const TextStyle(
                                        color: Color(0xFF202A22),
                                        fontSize: 23,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      lang == 'bn' ? 'শুরু হতে বাকি' : 'Time remaining',
                                      style: const TextStyle(
                                        color: Color(0xFF554C2D),
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _countdown(remaining, s),
                                      style: const TextStyle(
                                        color: Color(0xFF1D2821),
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0x55B99E42),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 18, color: Color(0xFF28291D)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: city.id,
                                          isExpanded: true,
                                          icon: const Icon(Icons.keyboard_arrow_down,
                                              color: Color(0xFF28291D)),
                                          style: const TextStyle(
                                            color: Color(0xFF28291D),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          items: [
                                            for (final item in cities)
                                              DropdownMenuItem(
                                                value: item.id,
                                                child: Text(
                                                  item.name(lang),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                          ],
                                          onChanged: (value) {
                                            if (value != null) _saveCity(value);
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 6,
                              child: Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0x55B99E42),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        (lang == 'bn' ? 'উদয় ' : 'Rise ') +
                                            _clockTime(prayers.sunrise, s),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF28291D),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 22,
                                      width: 1,
                                      color: const Color(0x77584D2C),
                                    ),
                                    Flexible(
                                      child: Text(
                                        (lang == 'bn' ? 'অস্ত ' : 'Set ') +
                                            _clockTime(prayers.maghrib, s),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF28291D),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          lang == 'bn'
                              ? 'সূর্যাস্তের সময় মাগরিবের গণনাকৃত সময়ের সমতুল্য ধরে দেখানো হয়েছে'
                              : 'Sunset is approximated by the calculated Maghrib time',
                          style: const TextStyle(
                            color: Color(0xFF5A542F),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 16, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            lang == 'bn' ? 'নামাজের সময়সূচি' : 'Prayer Times',
                            style: const TextStyle(
                              color: Color(0xFFE5EDEF),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        PopupMenuButton<PrayerCalculation>(
                          tooltip: s.t('calculation_method'),
                          icon: const Icon(Icons.tune, color: Color(0xFFB9C7CB)),
                          initialValue: _method,
                          onSelected: _saveMethod,
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: PrayerCalculation.karachi,
                              child: Text(s.t('karachi')),
                            ),
                            PopupMenuItem(
                              value: PrayerCalculation.muslimWorldLeague,
                              child: Text(s.t('mwl')),
                            ),
                            PopupMenuItem(
                              value: PrayerCalculation.egyptian,
                              child: Text(s.t('egypt')),
                            ),
                            PopupMenuItem(
                              value: PrayerCalculation.dubai,
                              child: Text(s.t('dubai')),
                            ),
                          ],
                        ),
                        PopupMenuButton<bool>(
                          tooltip: s.t('asr_method'),
                          icon: const Icon(Icons.access_time, color: Color(0xFFB9C7CB)),
                          initialValue: _hanafi,
                          onSelected: _saveAsr,
                          itemBuilder: (context) => [
                            PopupMenuItem(value: true, child: Text(s.t('hanafi'))),
                            PopupMenuItem(value: false, child: Text(s.t('shafi'))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF202B30),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < todayEntries.length; i++) ...[
                          Builder(
                            builder: (context) {
                              final entry = todayEntries[i];
                              final endTime = i < todayEntries.length - 1
                                  ? todayEntries[i + 1].value.subtract(const Duration(minutes: 1))
                                  : tomorrow.fajr.subtract(const Duration(minutes: 1));
                              final isNext = entry.key == upcoming.key;
                              final isDone = prayerDoneKeys.contains(entry.key);
                              final icon = switch (entry.key) {
                                'fajr' => Icons.wb_twilight,
                                'dhuhr' => Icons.wb_sunny,
                                'asr' => Icons.wb_sunny_outlined,
                                'maghrib' => Icons.cloud,
                                _ => Icons.nightlight_round,
                              };
                              return InkWell(
                                onTap: () => _openTool(
                                  context,
                                  const IbadahToolsScreen(section: IbadahToolsSection.prayers),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        icon,
                                        size: 21,
                                        color: isNext
                                            ? const Color(0xFFFFD66B)
                                            : isDone
                                                ? const Color(0xFF63C99A)
                                                : const Color(0xFFAAB6BB),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Text(
                                          s.t(entry.key),
                                          style: TextStyle(
                                            color: isNext
                                                ? const Color(0xFFF4F7F8)
                                                : isDone
                                                    ? const Color(0xFF8ECBAF)
                                                    : const Color(0xFFB6C1C5),
                                            fontSize: 15,
                                            fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (isNext)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.only(right: 10),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFD99B26),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      Text(
                                        '${_clockTime(entry.value, s)} - ${_clockTime(endTime, s)}',
                                        style: TextStyle(
                                          color: isNext
                                              ? const Color(0xFFE8EFF1)
                                              : const Color(0xFF9BA9AE),
                                          fontSize: 12,
                                          fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        tooltip: isDone
                                            ? (lang == 'bn' ? 'আদায় করা হয়েছে' : 'Marked complete')
                                            : (lang == 'bn' ? 'নামাজ আদায় হয়েছে চিহ্নিত করুন' : 'Mark prayer complete'),
                                        onPressed: () => _togglePrayerFromHome(
                                          entry.key,
                                          prayerDoneKeys,
                                          todayKey,
                                        ),
                                        icon: Icon(
                                          isDone
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          color: isDone
                                              ? const Color(0xFF58C78F)
                                              : const Color(0xFF69777D),
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          if (i < todayEntries.length - 1)
                            const Divider(
                              height: 1,
                              thickness: .5,
                              indent: 54,
                              endIndent: 16,
                              color: Color(0xFF354248),
                            ),
                        ],
                        const Divider(height: 1, color: Color(0xFF354248)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () => _openTool(
                                    context,
                                    const IbadahToolsScreen(section: IbadahToolsSection.prayers),
                                  ),
                                  icon: const Icon(Icons.notifications_none,
                                      color: Color(0xFFE2EBEE)),
                                  label: Text(
                                    lang == 'bn' ? 'নামাজের হিসাব' : 'Prayer tracker',
                                    style: const TextStyle(color: Color(0xFFE2EBEE)),
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 34,
                                color: const Color(0xFF667278),
                              ),
                              Expanded(
                                child: PopupMenuButton<int>(
                                  tooltip: s.t('hijri_adjustment'),
                                  initialValue: _hijriOffset,
                                  onSelected: _saveHijriOffset,
                                  itemBuilder: (context) => [
                                    PopupMenuItem(value: -1, child: Text(s.t('hijri_minus_one'))),
                                    PopupMenuItem(value: 0, child: Text(s.t('hijri_no_adjustment'))),
                                    PopupMenuItem(value: 1, child: Text(s.t('hijri_plus_one'))),
                                  ],
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.calendar_month_outlined,
                                            color: Color(0xFFE2EBEE)),
                                        const SizedBox(width: 8),
                                        Text(
                                          lang == 'bn' ? 'ক্যালেন্ডার' : 'Calendar',
                                          style: const TextStyle(color: Color(0xFFE2EBEE)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            lang == 'bn' ? 'টপ ফিচার' : 'Top Features',
                            style: const TextStyle(
                              color: Color(0xFFE7EFF1),
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => ref.read(mainNavigationIndexProvider.notifier).state = 1,
                          child: Text(
                            lang == 'bn' ? 'আরও দেখুন' : 'See all',
                            style: const TextStyle(
                              color: Color(0xFF36AA82),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Wrap(
                      alignment: WrapAlignment.spaceEvenly,
                      runAlignment: WrapAlignment.start,
                      spacing: 8,
                      runSpacing: 14,
                      children: [
                        _HomeCircleFeature(
                          title: lang == 'bn' ? 'ট্র্যাকার' : 'Tracker',
                          icon: Icons.track_changes,
                          detail: '$prayerPercent%',
                          progress: prayerDone / 5,
                          onTap: () => _openTool(
                            context,
                            const IbadahToolsScreen(section: IbadahToolsSection.prayers),
                          ),
                        ),
                        _HomeCircleFeature(
                          title: lang == 'bn' ? 'হাদিস' : 'Hadith',
                          icon: Icons.menu_book_outlined,
                          onTap: () => ref.read(mainNavigationIndexProvider.notifier).state = 2,
                        ),
                        _HomeCircleFeature(
                          title: lang == 'bn' ? 'রুকইয়াহ' : 'Ruqyah',
                          icon: Icons.auto_awesome_outlined,
                          onTap: () => _openTool(context, const RuqyahScreen()),
                        ),
                        _HomeCircleFeature(
                          title: lang == 'bn' ? '৯৯ নাম' : '99 Names',
                          icon: Icons.favorite_outline,
                          onTap: () => _openTool(
                            context,
                            const IbadahToolsScreen(section: IbadahToolsSection.names),
                          ),
                        ),
                        _HomeCircleFeature(
                          title: lang == 'bn' ? 'তাসবিহ' : 'Tasbih',
                          icon: Icons.fingerprint,
                          onTap: () => _openTool(context, const TasbihScreen()),
                        ),
                        _HomeCircleFeature(
                          title: lang == 'bn' ? 'দোয়া' : 'Dua',
                          icon: Icons.volunteer_activism_outlined,
                          onTap: () => ref.read(mainNavigationIndexProvider.notifier).state = 3,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                    child: Text(
                      s.t('daily_hadith'),
                      style: const TextStyle(
                        color: Color(0xFFE7EFF1),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: hadithAsync.when(
                      loading: () => const Card(
                        color: Color(0xFF26343A),
                        child: Padding(
                          padding: EdgeInsets.all(18),
                          child: LinearProgressIndicator(),
                        ),
                      ),
                      error: (error, stack) => Card(
                        color: const Color(0xFF26343A),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            s.t('daily_hadith_empty'),
                            style: const TextStyle(color: Color(0xFFE6EEF0)),
                          ),
                        ),
                      ),
                      data: (list) {
                        final eligible = list
                            .where((item) => item.verified && item.dailyEligible)
                            .toList();
                        if (eligible.isEmpty) {
                          return Card(
                            color: const Color(0xFF26343A),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Text(
                                s.t('daily_hadith_empty'),
                                style: const TextStyle(color: Color(0xFFE6EEF0)),
                              ),
                            ),
                          );
                        }
                        final item = eligible[dailyHadithIndex(_now, eligible.length)];
                        return Card(
                          color: const Color(0xFF26343A),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang == 'bn' ? item.category : item.categoryEn,
                                  style: const TextStyle(
                                    color: Color(0xFF66C69C),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (item.arabicText.isNotEmpty)
                                  Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text(
                                      item.arabicText,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        color: Color(0xFFF2F5F6),
                                        fontSize: 22,
                                        height: 1.8,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                Text(
                                  lang == 'bn' ? item.banglaTranslation : item.englishTranslation,
                                  style: const TextStyle(
                                    color: Color(0xFFE3EAEC),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  s.t('source') + ': ' + item.source + '  •  ' +
                                      s.t('reference') + ': ' + item.reference,
                                  style: const TextStyle(
                                    color: Color(0xFFAAB7BC),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}


class _LanguageChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF243B2D) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF343321),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PrayerCountdownArcPainter extends CustomPainter {
  final double progress;

  const _PrayerCountdownArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 11.0;
    // Keep the complete upper semicircle inside the available paint area.
    // The old fixed 210px minimum diameter pushed the arc outside this
    // 174px-high widget, clipping the top or bottom on different screens.
    // Place the arc's baseline at the lower edge while keeping the upper
    // semicircle fully inside the compact header on narrow and tall screens.
    final centerY = size.height - strokeWidth / 2 - 1;
    final maxRadiusByWidth = (size.width - strokeWidth - 20) / 2;
    final maxRadiusByHeight = centerY - strokeWidth / 2 - 5;
    final radius = math.min(maxRadiusByWidth, maxRadiusByHeight);
    if (radius <= 0) return;

    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, centerY),
      radius: radius,
    );
    final track = Paint()
      ..color = const Color(0xFFDAC66D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final active = Paint()
      ..color = const Color(0xFF203B31)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Negative sweep draws the upper half of the circle, like a prayer-time arch.
    canvas.drawArc(rect, math.pi, -math.pi, false, track);
    canvas.drawArc(
      rect,
      math.pi,
      -math.pi * progress.clamp(0.0, 1.0).toDouble(),
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _PrayerCountdownArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _HomeCircleFeature extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? detail;
  final double? progress;
  final VoidCallback onTap;

  const _HomeCircleFeature({
    required this.title,
    required this.icon,
    required this.onTap,
    this.detail,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          children: [
            SizedBox(
              width: 66,
              height: 66,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (progress != null)
                    SizedBox(
                      width: 66,
                      height: 66,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 5,
                        backgroundColor: const Color(0xFF7A4141),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF46B98D),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 66,
                      height: 66,
                      decoration: const BoxDecoration(
                        color: Color(0xFF173B2C),
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (detail != null)
                    Text(
                      detail!,
                      style: const TextStyle(
                        color: Color(0xFFEAF2F3),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    )
                  else
                    Icon(
                      icon,
                      color: const Color(0xFFF1F6F3),
                      size: 30,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFC6D0D3),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
