import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/services/prefs.dart';
import '../services/qibla_calculator.dart';

class _QiblaCity {
  final String id;
  final String nameBn;
  final String nameEn;
  final double lat;
  final double lng;

  const _QiblaCity(this.id, this.nameBn, this.nameEn, this.lat, this.lng);

  factory _QiblaCity.fromJson(Map<String, dynamic> json) => _QiblaCity(
        json['id'] as String,
        json['name_bn'] as String,
        json['name_en'] as String,
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      );
}

final _qiblaCityProvider = FutureProvider.autoDispose<_QiblaCity>((ref) async {
  final prefs = ref.read(sharedPrefsProvider);
  final selectedCity = prefs.getString('home_city') ?? 'dhaka';
  final raw = await rootBundle.loadString('assets/data/cities_bd.json');
  final items = (jsonDecode(raw) as List)
      .map((item) => _QiblaCity.fromJson(item as Map<String, dynamic>))
      .toList();
  return items.firstWhere(
    (city) => city.id == selectedCity,
    orElse: () => items.first,
  );
});

class QiblaScreen extends ConsumerWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final bn = strings.lang == 'bn';
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cityAsync = ref.watch(_qiblaCityProvider);

    return Scaffold(
      appBar: AppBar(title: Text(bn ? 'কিবলা কম্পাস' : 'Qibla Compass')),
      body: cityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(bn ? 'শহরের তথ্য লোড করা যায়নি।' : 'Could not load city information.'),
        ),
        data: (city) {
          final bearing = QiblaCalculator.bearing(
            latitude: city.lat,
            longitude: city.lng,
          );
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Text(
                        bn ? 'নির্বাচিত শহর' : 'Selected city',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bn ? city.nameBn : city.nameEn,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 18),
                      StreamBuilder<CompassEvent>(
                        stream: FlutterCompass.events?.cast<CompassEvent>(),
                        builder: (context, snapshot) {
                          final heading = snapshot.data?.heading;
                          if (heading == null || !heading.isFinite) {
                            return Column(
                              children: [
                                Icon(
                                  Icons.explore_off_outlined,
                                  size: 92,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  bn
                                      ? 'এই ফোনে কম্পাস সেন্সর পাওয়া যাচ্ছে না। নিচে কিবলার হিসাব করা দিক দেওয়া আছে।'
                                      : 'Compass sensor data is unavailable on this phone. The calculated Qibla bearing is shown below.',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            );
                          }
                          final relative = QiblaCalculator.relativeAngle(
                            qiblaBearing: bearing,
                            phoneHeading: heading,
                          ) * math.pi / 180;
                          return Column(
                            children: [
                              SizedBox(
                                width: 260,
                                height: 260,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 250,
                                      height: 250,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: scheme.outlineVariant,
                                          width: 2,
                                        ),
                                        color: scheme.surfaceContainerLow,
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      child: Text(
                                        'N',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 12,
                                      child: Text('S', style: theme.textTheme.labelLarge),
                                    ),
                                    Positioned(
                                      left: 14,
                                      child: Text('W', style: theme.textTheme.labelLarge),
                                    ),
                                    Positioned(
                                      right: 14,
                                      child: Text('E', style: theme.textTheme.labelLarge),
                                    ),
                                    Transform.rotate(
                                      angle: relative,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.navigation,
                                            size: 112,
                                            color: scheme.primary,
                                          ),
                                          Icon(
                                            Icons.mosque,
                                            size: 30,
                                            color: scheme.tertiary,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: scheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                bn ? 'ফোন ঘুরিয়ে তীরটি কিবলার দিকে মেলান' : 'Turn your phone until the arrow points to the Qibla',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '${bearing.toStringAsFixed(1)}°',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        bn
                            ? 'উত্তর দিক থেকে ঘড়ির কাঁটার দিকে কিবলার কোণ'
                            : 'Calculated Qibla bearing clockwise from north',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                bn
                    ? 'দিকটি হোম স্ক্রিনে নির্বাচিত শহরের স্থানাঙ্ক ধরে হিসাব করা হয়েছে, তাই এটি শহরভিত্তিক আনুমানিক দিক। চৌম্বকীয় উত্তর ও ভৌগোলিক উত্তরের পার্থক্যে কিছু বিচ্যুতি হতে পারে। ধাতব বস্তু ও চুম্বক থেকে ফোন দূরে রাখুন এবং প্রয়োজনে আটের মতো করে নাড়িয়ে সেন্সর ক্যালিব্রেট করুন।'
                    : 'The bearing uses the city selected on the Home screen, so it is a city-level approximation. Magnetic north can differ from geographic north, which may cause a small variation. Keep the phone away from metal and magnets, and move it in a figure-eight pattern to recalibrate when needed.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
