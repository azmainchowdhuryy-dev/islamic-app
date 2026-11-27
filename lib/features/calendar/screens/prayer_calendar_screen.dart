import 'dart:convert';
import 'dart:ui' show FontFeature;

import 'package:material_ui/material_ui.dart';
import 'package:bangla_utilities/bangla_utilities.dart';
import 'package:flutter/services.dart';
import 'package:hijri_date_time/hijri_date_time.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../home/services/prayer_calculator.dart';
import '../../../core/time/bangladesh_clock.dart';

const Color _background = Color(0xFF121B18);
const Color _surface = Color(0xFF1A2622);
const Color _accent = Color(0xFF10B981);
const Color _accentDeep = Color(0xFF1E8E68);
const Color _muted = Color(0xFFA6B8B1);
const Color _divider = Color(0xFF2A3B35);
const Color _dangerSurface = Color(0xFF331E20);
const Color _danger = Color(0xFFEF5350);

String toBanglaDigits(Object value) {
  const english = '0123456789';
  const bangla = '০১২৩৪৫৬৭৮৯';
  return value.toString().split('').map((character) {
    final index = english.indexOf(character);
    return index < 0 ? character : bangla[index];
  }).join();
}

class _District {
  final String id;
  final String nameBn;
  final String nameEn;
  final double latitude;
  final double longitude;

  const _District({
    required this.id,
    required this.nameBn,
    required this.nameEn,
    required this.latitude,
    required this.longitude,
  });

  factory _District.fromJson(Map<String, dynamic> json) => _District(
        id: json['id'] as String,
        nameBn: json['name_bn'] as String,
        nameEn: json['name_en'] as String,
        latitude: (json['lat'] as num).toDouble(),
        longitude: (json['lng'] as num).toDouble(),
      );
}

class PrayerCalendarScreen extends StatefulWidget {
  const PrayerCalendarScreen({super.key});

  @override
  State<PrayerCalendarScreen> createState() => _PrayerCalendarScreenState();
}

class _PrayerCalendarScreenState extends State<PrayerCalendarScreen> {
  static const _months = [
    'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
    'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
  ];
  static const _weekdays = [
    'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি', 'রবি',
  ];
  static const _hijriMonths = [
    'মুহাররম', 'সফর', 'রবিউল আউয়াল', 'রবিউস সানি',
    'জমাদিউল আউয়াল', 'জুমাদাল আখিরাহ', 'রজব', 'শাবান',
    'রমজান', 'শাওয়াল', 'জিলকদ', 'জিলহজ',
  ];

  final Future<List<_District>> _districtsFuture = _loadDistricts();
  DateTime _selectedDate = bangladeshCalendarDate(DateTime.now());
  String _districtId = 'dhaka';
  PrayerCalculation _method = PrayerCalculation.karachi;
  int _hijriOffset = 0;
  bool _hanafi = true;
  bool _preferencesLoaded = false;

  static Future<List<_District>> _loadDistricts() async {
    final json = await rootBundle.loadString('assets/data/cities_bd.json');
    final values = jsonDecode(json) as List<dynamic>;
    final districts = values
        .map((value) => _District.fromJson(value as Map<String, dynamic>))
        .toList();
    if (districts.isEmpty) {
      throw const FormatException('জেলার তালিকা পাওয়া যায়নি।');
    }
    return districts;
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final index = (prefs.getInt('home_calc_method') ?? 0)
        .clamp(0, PrayerCalculation.values.length - 1)
        .toInt();
    setState(() {
      _districtId = prefs.getString('home_city') ?? 'dhaka';
      _method = PrayerCalculation.values[index];
      _hijriOffset = (prefs.getInt('hijri_offset') ?? 0).clamp(-1, 1).toInt();
      _hanafi = prefs.getBool('home_hanafi') ?? true;
      _preferencesLoaded = true;
    });
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  String _time(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final hours = hour.toString().padLeft(2, '0');
    final minutes = value.minute.toString().padLeft(2, '0');
    return toBanglaDigits(hours + ':' + minutes);
  }

  String _range(DateTime start, DateTime end) =>
      _time(start) + ' – ' + _time(end);

  String get _calculationMethodLabel {
    switch (_method) {
      case PrayerCalculation.karachi:
        return 'করাচি';
      case PrayerCalculation.muslimWorldLeague:
        return 'মুসলিম ওয়ার্ল্ড লীগ';
      case PrayerCalculation.egyptian:
        return 'মিশরীয়';
      case PrayerCalculation.dubai:
        return 'দুবাই';
    }
  }

  String get _asrMethodLabel => _hanafi ? 'হানাফি' : 'শাফেয়ি';

  DailyPrayerTimes _calculate(_District district, DateTime date) {
    return DailyPrayerTimes.calculate(
      latitude: district.latitude,
      longitude: district.longitude,
      date: date,
      hanafi: _hanafi,
      method: _method,
    );
  }

  Future<void> _setHijriOffset(int value) async {
    setState(() => _hijriOffset = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hijri_offset', value);
  }

  Future<void> _setDistrict(_District district) async {
    setState(() => _districtId = district.id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('home_city', district.id);
  }

  Future<void> _openDistrictPicker() async {
    final districts = await _districtsFuture;
    if (!mounted) return;
    final selected = await showModalBottomSheet<_District>(
      context: context,
      backgroundColor: _surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.72,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: _muted.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('জেলা নির্বাচন করুন',
                      style: TextStyle(color: Colors.white, fontSize: 18,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: districts.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: _divider),
                  itemBuilder: (context, index) {
                    final district = districts[index];
                    final selectedNow = district.id == _districtId;
                    return ListTile(
                      title: Text(
                        district.nameBn,
                        style: TextStyle(
                          color: selectedNow ? _accent : Colors.white,
                          fontWeight: selectedNow
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(district.nameEn,
                          style: const TextStyle(color: _muted)),
                      trailing: selectedNow
                          ? const Icon(Icons.check_circle, color: _accent)
                          : null,
                      onTap: () => Navigator.of(sheetContext).pop(district),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) await _setDistrict(selected);
  }

  Future<void> _openDatePicker() async {
    final chosen = await showDialog<DateTime>(
      context: context,
      builder: (_) => _BengaliDatePickerDialog(
        initialDate: _selectedDate,
        firstYear: 2020,
        lastYear: 2035,
      ),
    );
    if (chosen != null && mounted) {
      setState(() => _selectedDate = _dateOnly(chosen));
    }
  }

  Future<void> _shareSchedule(
    _District district,
    DailyPrayerTimes prayers,
    DailyPrayerTimes tomorrow,
  ) async {
    final date = _selectedDate;
    final bangla = BanglaDate.fromDateTime(date);
    final hijri =
        HijriDateTime.fromGregorian(date).add(Duration(days: _hijriOffset));
    final lastThird = DailyPrayerTimes.tahajjudStart(
      prayers.maghrib,
      tomorrow.fajr,
    );
    final shareText = [
      'নামাজের সময়সূচী',
      'জেলা: ' + district.nameBn,
      'তারিখ: ' + toBanglaDigits(date.day) + ' ' +
          _months[date.month - 1] + ', ' + toBanglaDigits(date.year),
      'বাংলা: ' + toBanglaDigits(bangla.dayInt) + ' ' +
          bangla.monthName + ', ' + toBanglaDigits(bangla.yearInt),
      'হিজরি: ' + toBanglaDigits(hijri.day) + ' ' +
          _hijriMonths[hijri.month - 1] + ', ' + toBanglaDigits(hijri.year),
      '',
      'ফজর: ' + _time(prayers.fajr),
      'সূর্যোদয়: ' + _time(prayers.sunrise),
      'যুহর: ' + _time(prayers.dhuhr),
      'আসর: ' + _time(prayers.asr),
      'মাগরিব: ' + _time(prayers.maghrib),
      'ইশা: ' + _time(prayers.isha),
      'রাতের শেষ ১/৩ শুরু: ' + _time(lastThird),
      '',
      'হিসাব: Adhan, $_calculationMethodLabel পদ্ধতি, $_asrMethodLabel আসর, বাংলাদেশ সময় (UTC+৬)।',
    ].join('\n');
    await SharePlus.instance.share(ShareParams(text: shareText));
  }

  Future<void> _showReferences(String title, List<String> references) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                  color: Colors.white, fontSize: 18,
                  fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              for (final reference in references)
                Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.menu_book_outlined,
                          size: 17, color: _accent),
                      const SizedBox(width: 10),
                      Expanded(child: Text(reference, style: const TextStyle(
                          color: _muted, height: 1.5, fontSize: 13))),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              const Text(
                'দেখানো অতিরিক্ত মিনিটগুলো গণনাভিত্তিক আনুমানিক সীমা। স্থানীয় মসজিদের নির্ভরযোগ্য সময়সূচির সঙ্গে মিলিয়ে নিন।',
                style: TextStyle(color: Colors.white70, height: 1.5, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _referenceButton(String title, List<String> references) {
    return TextButton(
      onPressed: () => _showReferences(title, references),
      style: TextButton.styleFrom(
        foregroundColor: _accent,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text('রেফারেন্স দেখুন',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    List<String>? references,
    bool danger = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _divider.withValues(alpha: 0.55)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: TextStyle(
                color: danger ? _danger : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ))),
              if (references != null) _referenceButton(title, references),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _detailLine(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(
              color: color, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text(text, style: TextStyle(color: color, fontSize: 11.5)),
        ],
      ),
    );
  }

  Widget _prayerRow(
    String title,
    DateTime time, {
    Key? timeKey,
    String? firstDetail,
    Color firstColor = _muted,
    String? secondDetail,
    Color secondColor = _muted,
    String? thirdDetail,
    Color thirdColor = _muted,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                    color: Colors.white, fontSize: 14,
                    fontWeight: FontWeight.w600)),
                if (firstDetail != null) _detailLine(firstDetail, firstColor),
                if (secondDetail != null) _detailLine(secondDetail, secondColor),
                if (thirdDetail != null) _detailLine(thirdDetail, thirdColor),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(_time(time), key: timeKey, style: const TextStyle(
              color: Colors.white, fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }

  Widget _rangeRow(String title, String value,
      {String? subtitle, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 19, color: _accent),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                    color: Colors.white, fontSize: 14,
                    fontWeight: FontWeight.w600)),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(
                      color: _muted, fontSize: 11)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(value, textAlign: TextAlign.end, style: const TextStyle(
              color: Colors.white, fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }

  Widget _forbiddenTile(String title, DateTime start, DateTime end) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 12),
        decoration: BoxDecoration(
          color: _dangerSurface,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(
                color: _danger, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(_range(start, end), textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()])),
          ],
        ),
      ),
    );
  }

  Widget _dateHeader(_District district, DateTime date) {
    final bangla = BanglaDate.fromDateTime(date);
    final gregorianText = toBanglaDigits(date.day) + ' ' +
        _months[date.month - 1] + ', ' + toBanglaDigits(date.year);
    final banglaText = toBanglaDigits(bangla.dayInt) + ' ' +
        bangla.monthName + ', ' + toBanglaDigits(bangla.yearInt);
    return Row(
      children: [
        InkWell(
          onTap: _openDistrictPicker,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
                color: _accentDeep, borderRadius: BorderRadius.circular(22)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: Colors.white),
              const SizedBox(width: 5),
              Text(district.nameBn, style: const TextStyle(
                  color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w700)),
              const SizedBox(width: 2),
              const Icon(Icons.keyboard_arrow_down,
                  size: 17, color: Colors.white),
            ]),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(gregorianText, maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white,
                      fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(banglaText, maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 11.5)),
            ],
          ),
        ),
        IconButton(
          key: const Key('calendar_open_date_picker'),
          tooltip: 'তারিখ নির্বাচন করুন',
          onPressed: _openDatePicker,
          icon: const Icon(Icons.calendar_month_outlined,
              color: _accent, size: 23),
        ),
      ],
    );
  }

  Widget _weeklyStrip(DateTime selectedDate) {
    final daysSinceFriday = (selectedDate.weekday + 2) % 7;
    final firstDay = selectedDate.subtract(Duration(days: daysSinceFriday));
    return Row(
      children: List.generate(7, (index) {
        final day = firstDay.add(Duration(days: index));
        final selected = day.year == selectedDate.year &&
            day.month == selectedDate.month && day.day == selectedDate.day;
        final bangladeshToday = bangladeshCalendarDate(DateTime.now());
        final today = day.year == bangladeshToday.year &&
            day.month == bangladeshToday.month &&
            day.day == bangladeshToday.day;
        final dayKey = 'calendar_weekday_' + day.year.toString() + '_' +
            day.month.toString() + '_' + day.day.toString();
        return Expanded(
          child: InkWell(
            key: Key(dayKey),
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _selectedDate = _dateOnly(day)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(children: [
                Text(_weekdays[day.weekday - 1], style: TextStyle(
                    color: selected ? _accent : _muted,
                    fontSize: 10, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  width: 35, height: 35, alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? _accent : Colors.transparent,
                    shape: BoxShape.circle,
                    border: today && !selected
                        ? Border.all(color: _accent) : null,
                  ),
                  child: Text(toBanglaDigits(day.day), style: TextStyle(
                      color: selected ? _background : Colors.white,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w600)),
                ),
                const SizedBox(height: 3),
                SizedBox(height: 12, child: today ? Text('আজ', style: TextStyle(
                    color: selected ? _accent : _muted,
                    fontSize: 9, fontWeight: FontWeight.w700)) : null),
              ]),
            ),
          ),
        );
      }),
    );
  }

  Widget _hijriPill(DateTime date) {
    final hijri =
        HijriDateTime.fromGregorian(date).add(Duration(days: _hijriOffset));
    final label = toBanglaDigits(hijri.day) + ' ' +
        _hijriMonths[hijri.month - 1] + ', ' + toBanglaDigits(hijri.year);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _accentDeep.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _accentDeep.withValues(alpha: 0.6)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.nightlight_round, color: _accent, size: 15),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(
              color: Color(0xFFD5F5E8), fontSize: 11.5,
              fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _calendarBody(_District district) {
    final date = _selectedDate;
    final prayers = _calculate(district, date);
    final tomorrow = _calculate(district, date.add(const Duration(days: 1)));
    final night = tomorrow.fajr.difference(prayers.maghrib);
    final lastThirdStart =
        DailyPrayerTimes.tahajjudStart(prayers.maghrib, tomorrow.fajr);
    final firstThirdEnd = prayers.maghrib.add(
        Duration(seconds: (night.inSeconds / 3).round()));
    final islamicMidnight = prayers.maghrib.add(
        Duration(seconds: (night.inSeconds / 2).round()));
    final duhaStart = DailyPrayerTimes.duhaStart(prayers.sunrise);
    final zenithStart = prayers.dhuhr.subtract(const Duration(minutes: 10));
    final sunriseEnd = prayers.sunrise.add(const Duration(minutes: 15));
    final sunsetStart = prayers.maghrib.subtract(const Duration(minutes: 15));

    return ListView(
      key: const Key('prayer_calendar_scroll_view'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        _dateHeader(district, date),
        const SizedBox(height: 7),
        _weeklyStrip(date),
        const SizedBox(height: 5),
        _hijriPill(date),
        const SizedBox(height: 18),
        _sectionCard(
          title: 'সালাতের সময়',
          references: const [
            'আল-কুরআন, সূরা আল-ইসরা ১৭:৭৮।',
            'সহিহ মুসলিম ৬১২e: পাঁচ ওয়াক্ত সালাতের সময়সীমা।',
            'আসরের সময় হানাফি মাযহাব অনুযায়ী গণনা করা হয়েছে।',
          ],
          child: Column(children: [
            _prayerRow('ফজর', prayers.fajr),
            const Divider(height: 1, color: _divider),
            _prayerRow('যুহর', prayers.dhuhr),
            const Divider(height: 1, color: _divider),
            _prayerRow('আসর', prayers.asr,
                timeKey: const Key('calendar_asr_time'),
                firstDetail: 'মাকরূহ: ' + _time(sunsetStart),
                firstColor: _danger),
            const Divider(height: 1, color: _divider),
            _prayerRow('মাগরিব', prayers.maghrib),
            const Divider(height: 1, color: _divider),
            _prayerRow('ইশা', prayers.isha,
                firstDetail: 'উত্তম সময়ের শেষ: ' + _time(firstThirdEnd),
                firstColor: _accent,
                secondDetail: 'মাকরূহ: ' + _time(islamicMidnight),
                secondColor: const Color(0xFFFFC857),
                thirdDetail: 'শেষ সময় (পরদিন ফজর শুরু): ' +
                    _time(DailyPrayerTimes.ishaEndTime(tomorrow.fajr)),
                thirdColor: _accent),
          ]),
        ),
        const SizedBox(height: 13),
        _sectionCard(
          title: 'নফল সালাতের সময়',
          references: const [
            'দুহা সালাত: সহিহ মুসলিম ৭১৯d।',
            'রাতের শেষ তৃতীয়াংশ: সহিহ আল-বুখারি ১১৪৫।',
            'তাহাজ্জুদের শেষ তৃতীয়াংশ মাগরিব থেকে পরদিন ফজর পর্যন্ত রাতের দৈর্ঘ্য ধরে গণনা করা হয়েছে।',
          ],
          child: Column(children: [
            _rangeRow('দুহা', _range(duhaStart, zenithStart),
                subtitle: 'সূর্যোদয়ের ১৫ মিনিট পর থেকে জাওয়ালের আগ পর্যন্ত',
                icon: Icons.wb_sunny_outlined),
            const Divider(height: 1, color: _divider),
            _rangeRow('জাওয়াল শুরু', _time(zenithStart),
                subtitle: 'যুহরের আনুমানিক ১০ মিনিট আগে',
                icon: Icons.wb_twilight),
            const Divider(height: 1, color: _divider),
            _rangeRow('আওয়াবিন', _range(prayers.maghrib, prayers.isha),
                subtitle: 'মাগরিবের পর থেকে ইশার আগে',
                icon: Icons.nightlight_outlined),
            const Divider(height: 1, color: _divider),
            _rangeRow('তাহাজ্জুদ', _range(prayers.isha, tomorrow.fajr),
                subtitle: 'ইশার পর থেকে পরদিন ফজর পর্যন্ত',
                icon: Icons.nights_stay_outlined),
            Padding(
              padding: const EdgeInsets.only(left: 29, top: 1),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _detailLine(
                    'রাতের শেষ ১/৩ শুরু: ' + _time(lastThirdStart), _accent),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 13),
        _sectionCard(
          title: 'সালাতের নিষিদ্ধ সময়',
          danger: true,
          references: const [
            'সহিহ মুসলিম ৮৩১: সূর্যোদয়, সূর্য ঠিক মাথার ওপর থাকা এবং সূর্যাস্তের সময় সালাত থেকে বিরত থাকার বর্ণনা।',
            'অ্যাপে সকাল ও সন্ধ্যার জন্য ১৫ মিনিট এবং জাওয়ালের জন্য ১০ মিনিটের সতর্কতামূলক সময় দেখানো হয়। এগুলো ব্যবহারিক আনুমানিক সীমা।',
          ],
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'এই সময়গুলোতে সালাত আদায় নিষিদ্ধ (ব্যতিক্রম: সূর্যাস্তকালীন একই দিনের আসর সালাত)',
              style: TextStyle(color: _muted, fontSize: 11.5, height: 1.5),
            ),
            const SizedBox(height: 13),
            Row(children: [
              _forbiddenTile('সকাল', prayers.sunrise, sunriseEnd),
              const SizedBox(width: 7),
              _forbiddenTile('দুপুর', zenithStart, prayers.dhuhr),
              const SizedBox(width: 7),
              _forbiddenTile('সন্ধ্যা', sunsetStart, prayers.maghrib),
            ]),
          ]),
        ),
        const SizedBox(height: 13),
        _sectionCard(
          title: 'সাওমের সময়সূচী',
          references: const [
            'আল-কুরআন, সূরা আল-বাকারা ২:১৮৭: সুবহে সাদিক থেকে রাত পর্যন্ত সাওমের সময়সীমা।',
            'সাহরি শেষের সময় ফজরের শুরু এবং ইফতারের সময় মাগরিবের শুরু ধরে দেখানো হয়েছে।',
          ],
          child: Column(children: [
            _rangeRow('সাহরি শেষ', _time(prayers.fajr),
                subtitle: 'ফজরের শুরু', icon: Icons.restaurant_outlined),
            const Divider(height: 1, color: _divider),
            _rangeRow('ইফতার', _time(prayers.maghrib),
                subtitle: 'মাগরিবের শুরু', icon: Icons.ramen_dining_outlined),
          ]),
        ),
        const SizedBox(height: 13),
        _sectionCard(
          title: 'সূর্যোদয় ও সূর্যাস্ত',
          references: const [
            'সূর্যোদয় ও সূর্যাস্তের সময় নির্বাচিত স্থান, তারিখ ও জ্যোতির্বৈজ্ঞানিক হিসাব থেকে নির্ণয় করা হয়।',
          ],
          child: Column(children: [
            _rangeRow('সূর্যোদয়', _time(prayers.sunrise),
                icon: Icons.wb_sunny_outlined),
            const Divider(height: 1, color: _divider),
            _rangeRow('সূর্যাস্ত', _time(prayers.maghrib),
                icon: Icons.wb_twilight),
          ]),
        ),
        const SizedBox(height: 14),
        Text(
          'হিসাবের পদ্ধতি: Adhan • $_calculationMethodLabel • $_asrMethodLabel • বাংলাদেশ সময় (UTC+৬)। স্থানীয় মসজিদের সময়সূচির সঙ্গে মিলিয়ে নিন।',
          key: const Key('calendar_calculation_method_note'),
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 10.5, height: 1.5),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'ফিরে যান',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text('ক্যালেন্ডার', style: TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          PopupMenuButton<int>(
            key: const Key('calendar_hijri_adjustment'),
            tooltip: 'হিজরি তারিখ সমন্বয়',
            initialValue: _hijriOffset,
            onSelected: _setHijriOffset,
            icon: const Icon(Icons.event_available_outlined,
                color: _accent, size: 21),
            itemBuilder: (context) => [
              const PopupMenuItem(value: -1, child: Text('১ দিন পিছিয়ে')),
              const PopupMenuItem(value: 0, child: Text('কোনো পরিবর্তন নয়')),
              const PopupMenuItem(value: 1, child: Text('১ দিন এগিয়ে')),
            ],
          ),
          IconButton(
            tooltip: 'সময়সূচী শেয়ার করুন',
            onPressed: _preferencesLoaded
                ? () async {
                    final districts = await _districtsFuture;
                    final district = districts.firstWhere(
                        (item) => item.id == _districtId,
                        orElse: () => districts.first);
                    final times = _calculate(district, _selectedDate);
                    final tomorrow = _calculate(
                        district, _selectedDate.add(const Duration(days: 1)));
                    await _shareSchedule(district, times, tomorrow);
                  }
                : null,
            icon: const Icon(Icons.share_outlined, color: _accent, size: 21),
          ),
          IconButton(
            tooltip: 'জেলার তালিকা',
            onPressed: _openDistrictPicker,
            icon: const Icon(Icons.list_alt_outlined, color: _accent, size: 23),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<List<_District>>(
        future: _districtsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: _accent));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('জেলার তথ্য লোড করা যায়নি। আবার চেষ্টা করুন।',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white)),
            ));
          }
          final districts = snapshot.data!;
          final district = districts.firstWhere((item) => item.id == _districtId,
              orElse: () => districts.first);
          return _calendarBody(district);
        },
      ),
    );
  }
}

class _BengaliDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final int firstYear;
  final int lastYear;

  const _BengaliDatePickerDialog({
    required this.initialDate,
    required this.firstYear,
    required this.lastYear,
  });

  @override
  State<_BengaliDatePickerDialog> createState() =>
      _BengaliDatePickerDialogState();
}

class _BengaliDatePickerDialogState extends State<_BengaliDatePickerDialog> {
  static const _months = [
    'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
    'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
  ];

  late int _year;
  late int _month;
  late int _day;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _yearController;

  int get _daysInMonth => DateUtils.getDaysInMonth(_year, _month);

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate;
    _year = initial.year.clamp(widget.firstYear, widget.lastYear).toInt();
    _month = initial.month;
    _day = initial.day.clamp(1, DateUtils.getDaysInMonth(_year, _month)).toInt();
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
    _dayController = FixedExtentScrollController(initialItem: _day - 1);
    _yearController = FixedExtentScrollController(
        initialItem: _year - widget.firstYear);
  }

  @override
  void dispose() {
    _monthController.dispose();
    _dayController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _clampDay() {
    final nextDay = _day.clamp(1, _daysInMonth).toInt();
    if (nextDay != _day) {
      _day = nextDay;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _dayController.hasClients) {
          _dayController.jumpToItem(_day - 1);
        }
      });
    }
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required int selectedIndex,
    required String Function(int) label,
    required ValueChanged<int> onChanged,
  }) {
    return Expanded(
      child: ListWheelScrollView(
        controller: controller,
        itemExtent: 42,
        diameterRatio: 1.45,
        perspective: 0.003,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        children: List.generate(itemCount, (index) {
          final selected = index == selectedIndex;
          return Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            decoration: BoxDecoration(
              color: selected
                  ? _accentDeep.withValues(alpha: 0.9)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(label(index), maxLines: 1, style: TextStyle(
                color: selected ? Colors.white : _muted,
                fontSize: selected ? 14 : 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500)),
          );
        }),
      ),
    );
  }

  void _chooseToday() {
    Navigator.of(context).pop(bangladeshCalendarDate(DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    _clampDay();
    final yearCount = widget.lastYear - widget.firstYear + 1;
    return Dialog(
      backgroundColor: _surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Expanded(child: Text('তারিখ নির্বাচন করুন',
                style: TextStyle(color: Colors.white, fontSize: 17,
                    fontWeight: FontWeight.w800))),
            TextButton(
              onPressed: _chooseToday,
              style: TextButton.styleFrom(
                backgroundColor: _accentDeep,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: const StadiumBorder(),
              ),
              child: const Text('আজ',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 12),
          SizedBox(height: 176, child: Row(children: [
            _wheel(
              controller: _monthController,
              itemCount: 12,
              selectedIndex: _month - 1,
              label: (index) => _months[index],
              onChanged: (index) => setState(() {
                _month = index + 1;
                _clampDay();
              }),
            ),
            _wheel(
              controller: _dayController,
              itemCount: _daysInMonth,
              selectedIndex: _day - 1,
              label: (index) =>
                  toBanglaDigits((index + 1).toString().padLeft(2, '0')),
              onChanged: (index) => setState(() => _day = index + 1),
            ),
            _wheel(
              controller: _yearController,
              itemCount: yearCount,
              selectedIndex: _year - widget.firstYear,
              label: (index) => toBanglaDigits(widget.firstYear + index),
              onChanged: (index) => setState(() {
                _year = widget.firstYear + index;
                _clampDay();
              }),
            ),
          ])),
          const SizedBox(height: 12),
          Row(children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: _muted),
              child: const Text('বাতিল'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(DateTime(_year, _month, _day)),
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: _background,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 11),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
              ),
              child: const Text('ঠিক আছে',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ]),
        ]),
      ),
    );
  }
}
