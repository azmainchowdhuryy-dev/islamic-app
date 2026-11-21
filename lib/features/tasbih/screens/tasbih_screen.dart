import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/services/feedback_service.dart';
import '../models/tasbih_state.dart';
import '../providers/tasbih_provider.dart';

class TasbihScreen extends ConsumerWidget {
  const TasbihScreen({super.key});

  void _onTap(BuildContext context, WidgetRef ref) {
    final s = ref.read(stringsProvider);
    final reached = ref.read(tasbihProvider.notifier).increment();
    final st = ref.read(tasbihProvider);
    unawaited(
      FeedbackService.tap(
        vibration: st.vibration,
        sound: st.sound,
        strong: reached,
      ),
    );
    if (reached) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(s.t('target_completed'))));
    }
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    final s = ref.read(stringsProvider);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.t('reset_title')),
        content: Text(s.t('reset_body')),
        actions: [
          TextButton(
            key: const Key('cancel_reset'),
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.t('cancel')),
          ),
          FilledButton(
            key: const Key('confirm_reset'),
            onPressed: () {
              ref.read(tasbihProvider.notifier).resetSession();
              Navigator.pop(ctx);
            },
            child: Text(s.t('reset')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final st = ref.watch(tasbihProvider);
    final c = st.active;
    final n = ref.read(tasbihProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (st.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(s.t('tasbih'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.t('tasbih'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // ১. জিকির নির্বাচন
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              for (final k in dhikrKeys) ButtonSegment(value: k, label: Text(s.t(k))),
            ],
            selected: {st.activeKey},
            onSelectionChanged: (v) => n.selectDhikr(v.first),
          ),
          const SizedBox(height: 16),

          // ২. বর্তমান ও মোট গণনা
          Row(children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    Text(s.t('session_count'), style: textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      '${s.digits(c.session)} / ${s.digits(c.target)}',
                      key: const Key('session_of_target'),
                      style: textTheme.titleLarge,
                    ),
                  ]),
                ),
              ),
            ),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    Text(s.t('total_count'), style: textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      s.digits(c.total),
                      key: const Key('total_count'),
                      style: textTheme.titleLarge,
                    ),
                  ]),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // ৩. বড় গোল বোতাম + অগ্রগতির রিং
          SizedBox(
            width: 260,
            height: 260,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 260,
                height: 260,
                child: CircularProgressIndicator(
                  value: c.progress,
                  strokeWidth: 10,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
              Material(
                color: scheme.primary,
                elevation: 4,
                shape: const CircleBorder(),
                child: InkWell(
                  key: const Key('tap_button'),
                  customBorder: const CircleBorder(),
                  onTap: () => _onTap(context, ref),
                  child: SizedBox(
                    width: 210,
                    height: 210,
                    child: Center(
                      child: Text(
                        s.digits(c.session),
                        key: const Key('session_count'),
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          if (c.completed)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.check_circle, color: scheme.primary),
              const SizedBox(width: 8),
              Text(s.t('target_done_label'), style: textTheme.titleMedium),
            ])
          else
            Text(s.t('tap_to_count')),
          const SizedBox(height: 20),

          // ৪. লক্ষ্য নির্বাচন
          Align(
            alignment: Alignment.centerLeft,
            child: Text(s.t('select_target'), style: textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in tasbihTargets)
                ChoiceChip(
                  key: Key('target_$t'),
                  label: Text(s.digits(t)),
                  selected: c.target == t,
                  onSelected: (_) => n.setTarget(t),
                ),
            ]),
          ),
          const SizedBox(height: 12),

          // ৫. কম্পন ও শব্দ
          Card(
            child: Column(children: [
              SwitchListTile(
                key: const Key('vibration_switch'),
                secondary: const Icon(Icons.vibration),
                title: Text(s.t('vibration')),
                value: st.vibration,
                onChanged: n.setVibration,
              ),
              SwitchListTile(
                key: const Key('sound_switch'),
                secondary: const Icon(Icons.volume_up_outlined),
                title: Text(s.t('sound')),
                value: st.sound,
                onChanged: n.setSound,
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // ৬. রিসেট
          OutlinedButton.icon(
            key: const Key('reset_button'),
            onPressed: () => _confirmReset(context, ref),
            icon: const Icon(Icons.restart_alt),
            label: Text(s.t('reset')),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}
