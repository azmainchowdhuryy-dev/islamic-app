import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';

class TasbihScreen extends ConsumerWidget {
  const TasbihScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider).t;
    return Scaffold(
      appBar: AppBar(title: Text(t('tasbih'))),
      body: Center(child: Text(t('coming_soon'))),
    );
  }
}
