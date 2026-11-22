import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bangla_utilities/bangla_utilities.dart';
import 'package:hijri_date_time/hijri_date_time.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/navigation/navigation_provider.dart';
import '../../../core/services/prefs.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_surface_styles.dart';
import '../../calendar/screens/prayer_calendar_screen.dart';
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
  final cities = data
      .map((item) => HomeCity.fromJson(item as Map<String, dynamic>))
      .toList();
  if (cities.isEmpty) {
    throw const FormatException('The Bangladesh city list is empty.');
  }
  return cities;
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
  Timer? _prayerSlideTimer;
  int _prayerSlideIndex = 0;
  String? _homePrayerOverrideDateKey;
  Set<String>? _homePrayerDoneOverride;
  Future<void> _prayerWriteQueue = Future<void>.value();

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
    _prayerSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() => _prayerSlideIndex = (_prayerSlideIndex + 1) % 2);
      }
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _prayerSlideTimer?.cancel();
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
    final base = _homePrayerOverrideDateKey == dateKey
        ? (_homePrayerDoneOverride ?? current)
        : current;
    final next = Set<String>.from(base);
    if (!next.add(key)) next.remove(key);

    setState(() {
      _homePrayerOverrideDateKey = dateKey;
      _homePrayerDoneOverride = next;
    });

    final prefs = ref.read(sharedPrefsProvider);
    final write = _prayerWriteQueue
        .catchError((_) {})
        .then<void>((_) async {
          await prefs.setStringList(
            'prayer_tracker_$dateKey',
            next.toList(),
          );
        });
    _prayerWriteQueue = write;

    try {
      await write;
    } catch (_) {
      // Keep the optimistic state visible if the local write temporarily fails.
      return;
    }

    if (mounted &&
        _homePrayerOverrideDateKey == dateKey &&
        identical(_homePrayerDoneOverride, next)) {
      setState(() {
        _homePrayerOverrideDateKey = null;
        _homePrayerDoneOverride = null;
      });
    }
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

  Future<void> _openPrayerCalendar(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const PrayerCalendarScreen(),
      ),
    );
    if (!mounted) return;
    final savedCity = ref.read(sharedPrefsProvider).getString('home_city');
    if (savedCity != null && savedCity != _cityId) {
      setState(() => _cityId = savedCity);
    }
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
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.bottomSurface,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.middleSurface,
        body: citiesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text(s.t('prayer_error'),
                style: const TextStyle(color: AppColors.primaryText)),
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
            final countdownPlan = PrayerCountdownPlan.calculate(
              now: _now,
              yesterday: yesterday,
              today: prayers,
              tomorrow: tomorrow,
            );
            final displayedCountdown =
                countdownPlan.items[_prayerSlideIndex % countdownPlan.items.length];
            final nextName = s.t(displayedCountdown.nameKey);
            final remaining = displayedCountdown.target.difference(_now);
            final countdownProgress = (1 -
                    remaining.inSeconds / const Duration(days: 1).inSeconds)
                .clamp(0.0, 1.0)
                .toDouble();

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
            final savedPrayerKeys = (todayPrefs
                        .getStringList('prayer_tracker_$todayKey') ??
                    [])
                .where(validPrayerKeys.contains)
                .toSet();
            final prayerDoneKeys = _homePrayerOverrideDateKey == todayKey
                ? Set<String>.from(_homePrayerDoneOverride ?? savedPrayerKeys)
                : savedPrayerKeys;
            final prayerDone = prayerDoneKeys.length;
            final prayerPercent = (prayerDone / 5 * 100).round();

            return SafeArea(
              top: false,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    key: const Key('home_header_panel'),
                    decoration: AppSurfaceStyles.hero(),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      MediaQuery.of(context).padding.top + 2,
                      16,
                      4,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              key: const Key('home_open_prayer_calendar'),
                              tooltip: 'ক্যালেন্ডার',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 36,
                                height: 36,
                              ),
                              onPressed: () => _openPrayerCalendar(context),
                              icon: const Icon(
                                Icons.calendar_month_outlined,
                                color: AppColors.primaryText,
                                size: 27,
                              ),
                            ),
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
                                      color: AppColors.primaryText,
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
                                      color: AppColors.secondaryText,
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
                          key: const Key('next_prayer_arc'),
                          height: 122,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: Center(
                                  child: SizedBox(
                                    key: const Key('next_prayer_curve'),
                                    width: math.min(
                                      MediaQuery.of(context).size.width * 0.72,
                                      260.0,
                                    ),
                                    height: 122,
                                    child: CustomPaint(
                                      painter: _PrayerCountdownArcPainter(
                                        progress: countdownProgress.toDouble(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 450),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder: (child, animation) =>
                                        SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.18, 0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                    ),
                                    child: Column(
                                      key: ValueKey(
                                        '$_prayerSlideIndex-${displayedCountdown.nameKey}-${displayedCountdown.statusKey}-${displayedCountdown.detailKey}',
                                      ),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          nextName,
                                          key: const Key('next_prayer_name'),
                                          style: TextStyle(
                                            color: (displayedCountdown.isProhibited ||
                                                    displayedCountdown.isImminent)
                                                ? AppColors.warmAmber
                                                : AppColors.primaryText,
                                            fontSize: 21,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        if (displayedCountdown.detailKey != null) ...[
                                          const SizedBox(height: 1),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.warmAmber,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              s.t(displayedCountdown.detailKey!),
                                              style: const TextStyle(
                                                color: Color(0xFF241407),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 1),
                                        Text(
                                          s.t(displayedCountdown.statusKey),
                                          key: const Key('next_prayer_remaining_label'),
                                          style: const TextStyle(
                                            color: AppColors.secondaryText,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          _countdown(remaining, s),
                                          key: const Key('next_prayer_countdown'),
                                          style: const TextStyle(
                                            color: AppColors.primaryText,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
                                height: 36,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.activeSurface,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 18, color: AppColors.primaryText),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: city.id,
                                          isExpanded: true,
                                          icon: const Icon(Icons.keyboard_arrow_down,
                                              color: AppColors.primaryText),
                                          style: const TextStyle(
                                            color: AppColors.primaryText,
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
                                  color: AppColors.activeSurface,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'সূর্যোদয় ' +
                                            _clockTime(prayers.sunrise, s),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.primaryText,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 22,
                                      width: 1,
                                      color: AppColors.subtleBorder,
                                    ),
                                    Flexible(
                                      child: Text(
                                        'সূর্যাস্ত ' +
                                            _clockTime(prayers.maghrib, s),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.primaryText,
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
                        const SizedBox(height: 2),
                        Text(
                          lang == 'bn'
                              ? 'সূর্যাস্তের সময় মাগরিবের গণনাকৃত সময়ের সমতুল্য ধরে দেখানো হয়েছে'
                              : 'Sunset is approximated by the calculated Maghrib time',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
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
                              color: AppColors.primaryText,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        PopupMenuButton<PrayerCalculation>(
                          tooltip: s.t('calculation_method'),
                          icon: const Icon(Icons.tune, color: AppColors.secondaryText),
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
                          icon: const Icon(Icons.access_time, color: AppColors.secondaryText),
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
                    key: const Key('home_prayer_times_card'),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: AppSurfaceStyles.middleCard(radius: 24),
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
                              final isNext = countdownPlan.items.any(
                                (item) => item.nameKey == entry.key && item.statusKey == 'starts_in',
                              );
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
                                child: Container(
                                  decoration: isNext
                                      ? AppSurfaceStyles.activeRow(radius: 12)
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                                    child: Row(
                                      children: [
                                      Icon(
                                        icon,
                                        size: 21,
                                        color: isNext
                                            ? AppColors.warmAmber
                                            : isDone
                                                ? AppColors.primaryAccent
                                                : AppColors.secondaryText,
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Text(
                                          s.t(entry.key),
                                          style: TextStyle(
                                            color: isNext
                                                ? AppColors.primaryText
                                                : isDone
                                                    ? AppColors.primaryAccent
                                                    : AppColors.secondaryText,
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
                                            color: AppColors.warmAmber,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      Text(
                                        '${_clockTime(entry.value, s)} - ${_clockTime(endTime, s)}',
                                        style: TextStyle(
                                          color: isNext
                                              ? AppColors.primaryText
                                              : AppColors.secondaryText,
                                          fontSize: 12,
                                          fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        key: Key('home_prayer_toggle_${entry.key}'),
                                        constraints: const BoxConstraints(
                                          minWidth: 40,
                                          minHeight: 40,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
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
                                              ? AppColors.primaryAccent
                                              : AppColors.secondaryText,
                                          size: 20,
                                        ),
                                      ),
                                      ],
                                    ),
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
                              color: AppColors.subtleBorder,
                            ),
                        ],
                        const Divider(height: 1, color: AppColors.subtleBorder),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () => _openTool(
                                    context,
                                    const IbadahToolsScreen(section: IbadahToolsSection.prayers),
                                  ),
                                  icon: const Icon(Icons.notifications_none,
                                      color: AppColors.primaryText),
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(0, 40),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  label: Text(
                                    lang == 'bn' ? 'নামাজের হিসাব' : 'Prayer tracker',
                                    style: const TextStyle(color: AppColors.primaryText),
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 34,
                                color: AppColors.subtleBorder,
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
                                            color: AppColors.primaryText),
                                        const SizedBox(width: 8),
                                        Text(
                                          lang == 'bn' ? 'ক্যালেন্ডার' : 'Calendar',
                                          style: const TextStyle(color: AppColors.primaryText),
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            lang == 'bn' ? 'টপ ফিচার' : 'Top Features',
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 32),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => ref.read(mainNavigationIndexProvider.notifier).state = 1,
                          child: Text(
                            lang == 'bn' ? 'আরও দেখুন' : 'See all',
                            style: const TextStyle(
                              color: AppColors.primaryAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisExtent: 96,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                      ),
                      children: [
                        _HomeCircleFeature(
                          title: 'ট্র্যাকার',
                          titleMaxLines: 2,
                          titleFontSize: 12,
                          icon: Icons.track_changes,
                          detail: '$prayerPercent%',
                          progress: prayerDone / 5,
                          onTap: () => _openTool(
                            context,
                            const IbadahToolsScreen(section: IbadahToolsSection.prayers),
                          ),
                        ),
                        _HomeCircleFeature(
                          title: lang == 'bn' ? 'আল্লাহর ৯৯ নাম' : '99 Names of Allah',
                          icon: Icons.favorite_outline,
                          titleFontSize: 10,
                          titleMaxLines: 2,
                          onTap: () => _openTool(
                            context,
                            const IbadahToolsScreen(section: IbadahToolsSection.names),
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
                        color: AppColors.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: hadithAsync.when(
                      loading: () => const Card(
                        color: AppColors.middleSurface,
                        child: Padding(
                          padding: EdgeInsets.all(18),
                          child: LinearProgressIndicator(),
                        ),
                      ),
                      error: (error, stack) => Card(
                        color: AppColors.middleSurface,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            s.t('daily_hadith_empty'),
                            style: const TextStyle(color: AppColors.primaryText),
                          ),
                        ),
                      ),
                      data: (list) {
                        final eligible = list
                            .where((item) => item.verified && item.dailyEligible)
                            .toList();
                        if (eligible.isEmpty) {
                          return Card(
                            color: AppColors.middleSurface,
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Text(
                                s.t('daily_hadith_empty'),
                                style: const TextStyle(color: AppColors.primaryText),
                              ),
                            ),
                          );
                        }
                        final item = eligible[dailyHadithIndex(_now, eligible.length)];
                        return Card(
                          color: AppColors.middleSurface,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang == 'bn' ? item.category : item.categoryEn,
                                  style: const TextStyle(
                                    color: AppColors.primaryAccent,
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
                                        color: AppColors.primaryText,
                                        fontSize: 22,
                                        height: 1.8,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                Text(
                                  lang == 'bn' ? item.banglaTranslation : item.englishTranslation,
                                  style: const TextStyle(
                                    color: AppColors.primaryText,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${s.t('source')}: ${item.source}  •  ${s.t('reference')}: ${item.reference}',
                                  style: const TextStyle(
                                    color: AppColors.secondaryText,
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
          color: selected ? AppColors.activeSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.secondaryText,
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
    const strokeWidth = 9.0;
    // A compact, almost circular arch leaves breathing room at both sides.
    final centerY = size.height - strokeWidth / 2 - 1;
    final horizontalInset = math.min(10.0, size.width / 12);
    final arcTop = strokeWidth / 2 + 1;
    if (centerY <= arcTop || size.width <= horizontalInset * 2) return;
    final track = Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final active = Paint()
      ..color = const Color(0xFFE8F4F2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // The narrowed ellipse makes the arch rounder. The prayer name and
    // countdown remain centered inside its open lower half.
    final arcRect = Rect.fromLTRB(
      horizontalInset,
      arcTop,
      size.width - horizontalInset,
      2 * centerY - arcTop,
    );
    canvas.drawArc(arcRect, math.pi, math.pi, false, track);
    canvas.drawArc(
      arcRect,
      math.pi,
      math.pi * progress.clamp(0.0, 1.0).toDouble(),
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
  final double titleFontSize;
  final int titleMaxLines;
  final VoidCallback onTap;

  const _HomeCircleFeature({
    required this.title,
    required this.icon,
    required this.onTap,
    this.detail,
    this.progress,
    this.titleFontSize = 11.2,
    this.titleMaxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    // Keep the Top Features palette identical in Light, Dark and System modes.
    return SizedBox(
      width: 76,
      child: Material(
        color: AppColors.middleSurface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Column(
          children: [
            SizedBox(
              width: 53,
              height: 53,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (progress != null)
                    SizedBox(
                      width: 53,
                      height: 53,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        backgroundColor: AppColors.subtleBorder,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                      ),
                    )
                  else
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: AppColors.activeSurface,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (detail != null)
                    Text(
                      detail!,
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    )
                  else
                    Icon(
                      icon,
                      color: AppColors.primaryText,
                      size: 24,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: titleMaxLines,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
