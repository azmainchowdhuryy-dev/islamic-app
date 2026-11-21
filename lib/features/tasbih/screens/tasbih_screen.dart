import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/services/feedback_service.dart';
import '../models/tasbih_preset.dart';
import '../models/tasbih_state.dart';
import '../providers/tasbih_provider.dart';

class TasbihScreen extends ConsumerWidget {
  const TasbihScreen({super.key});

  void _onTap(BuildContext context, WidgetRef ref) {
    final strings = ref.read(stringsProvider);
    final reached = ref.read(tasbihProvider.notifier).increment();
    final state = ref.read(tasbihProvider);
    unawaited(
      FeedbackService.tap(
        vibration: state.vibration,
        sound: state.sound,
        strong: reached,
      ),
    );
    if (reached) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text(strings.t('target_completed'))),
        );
    }
  }

  void _confirmReset(BuildContext context, WidgetRef ref, AppStrings strings) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.t('reset_title')),
        content: Text(strings.t('reset_body')),
        actions: [
          TextButton(
            key: const Key('cancel_reset'),
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.t('cancel')),
          ),
          FilledButton(
            key: const Key('confirm_reset'),
            onPressed: () {
              ref.read(tasbihProvider.notifier).resetSession();
              Navigator.pop(dialogContext);
            },
            child: Text(strings.t('reset')),
          ),
        ],
      ),
    );
  }

  void _showPremiumNotice(BuildContext context, AppStrings strings) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.t('premium_title')),
        content: Text(strings.t('premium_coming_soon')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.t('close')),
          ),
        ],
      ),
    );
  }

  void _openTasbihSelector(
    BuildContext context,
    WidgetRef ref,
    String activeKey,
    AppStrings strings,
  ) {
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final sheetHeight = MediaQuery.of(sheetContext).size.height * 0.78;
        return SizedBox(
          height: sheetHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings.t('choose_tasbih'),
                          key: const Key('tasbih_selection_title'),
                          style: Theme.of(sheetContext).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        key: const Key('close_tasbih_selector'),
                        tooltip: strings.t('close'),
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                    itemCount: tasbihPresets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (itemContext, index) {
                      final preset = tasbihPresets[index];
                      final selected = preset.key == activeKey;
                      return Material(
                        color: selected
                            ? scheme.primaryContainer
                            : scheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: selected
                                ? scheme.primary
                                : scheme.outlineVariant,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: Key('tasbih_option_' + preset.key),
                          onTap: () {
                            if (preset.requiresPremium) {
                              Navigator.pop(sheetContext);
                              _showPremiumNotice(context, strings);
                              return;
                            }
                            ref
                                .read(tasbihProvider.notifier)
                                .selectDhikr(preset.key);
                            Navigator.pop(sheetContext);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: scheme.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _presetIcon(preset.iconName),
                                    color: scheme.primary,
                                    size: 23,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        preset.title(strings.lang),
                                        style: Theme.of(itemContext)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              color: scheme.onSurface,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      if (preset.arabic.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Directionality(
                                          textDirection: TextDirection.rtl,
                                          child: Text(
                                            preset.arabic,
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              color: scheme.onSurfaceVariant,
                                              fontSize: 17,
                                              height: 1.6,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 3),
                                      Text(
                                        strings.t('target') +
                                            ' ' +
                                            strings.digits(preset.target),
                                        style: Theme.of(itemContext)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (preset.requiresPremium)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Icon(
                                      Icons.workspace_premium,
                                      color: scheme.tertiary,
                                      size: 20,
                                    ),
                                  ),
                                Icon(
                                  selected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: selected
                                      ? scheme.primary
                                      : scheme.onSurfaceVariant,
                                  size: 23,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static IconData _presetIcon(String name) {
    switch (name) {
      case 'fingerprint':
        return Icons.fingerprint;
      case 'sparkles':
        return Icons.auto_awesome;
      case 'favorite':
        return Icons.favorite_outline;
      case 'star':
        return Icons.star_outline;
      case 'mosque':
        return Icons.account_balance_outlined;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'spa':
        return Icons.spa_outlined;
      case 'all_inclusive':
        return Icons.all_inclusive;
      case 'volunteer_activism':
        return Icons.volunteer_activism_outlined;
      default:
        return Icons.auto_awesome_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final state = ref.watch(tasbihProvider);
    final counter = state.active;
    final notifier = ref.read(tasbihProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final preset = tasbihPresetForKey(state.activeKey);
    final ringSize = math.min(MediaQuery.of(context).size.width - 48, 260.0);
    final buttonSize = ringSize * 0.79;

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(strings.t('tasbih')),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: strings.t('back'),
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(strings.t('tasbih')),
        centerTitle: true,
        actions: [
          IconButton(
            key: const Key('premium_button'),
            tooltip: strings.t('premium_title'),
            onPressed: () => _showPremiumNotice(context, strings),
            icon: const Icon(
              Icons.workspace_premium_outlined,
              color: scheme.tertiary,
            ),
          ),
          IconButton(
            key: const Key('reset_button'),
            tooltip: strings.t('reset'),
            onPressed: () => _confirmReset(context, ref, strings),
            icon: const Icon(Icons.restart_alt),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          children: [
            Material(
              color: scheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const Key('select_tasbih_button'),
                onTap: () => _openTasbihSelector(
                  context,
                  ref,
                  state.activeKey,
                  strings,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _presetIcon(preset.iconName),
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.t('active_tasbih'),
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              preset.title(strings.lang),
                              key: const Key('active_tasbih_title'),
                              style: textTheme.titleMedium?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (preset.arabic.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: Text(
                                  preset.arabic,
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: scheme.onSurfaceVariant,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Animated circular progress ring and the large increment button.
            SizedBox(
              width: ringSize,
              height: ringSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: counter.progress),
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    builder: (context, progress, _) => SizedBox(
                      width: ringSize,
                      height: ringSize,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                        backgroundColor: scheme.outlineVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                      ),
                    ),
                  ),
                  Material(
                    color: scheme.primaryContainer,
                    elevation: 3,
                    shape: const CircleBorder(),
                    child: InkWell(
                      key: const Key('tap_button'),
                      customBorder: const CircleBorder(),
                      onTap: () => _onTap(context, ref),
                      child: SizedBox(
                        width: buttonSize,
                        height: buttonSize,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                strings.digits(counter.session),
                                key: const Key('session_count'),
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontSize: ringSize * 0.22,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '/ ' + strings.digits(counter.target),
                                key: const Key('session_of_target'),
                                style: textTheme.titleMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                counter.completed
                                    ? strings.t('target_done_label')
                                    : strings.t('tap_to_count'),
                                textAlign: TextAlign.center,
                                style: textTheme.bodySmall?.copyWith(
                                  color: counter.completed
                                      ? scheme.primary
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (counter.completed)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    strings.t('target_done_label'),
                    style: textTheme.titleMedium,
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Lifetime total remains visible below the main counter.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.all_inclusive,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      strings.t('total_count'),
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    strings.digits(counter.total),
                    key: const Key('total_count'),
                    style: textTheme.titleLarge?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                strings.t('select_target'),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final target in tasbihTargets)
                    ChoiceChip(
                      key: Key('target_' + target.toString()),
                      label: Text(strings.digits(target)),
                      selected: counter.target == target,
                      onSelected: (_) => notifier.setTarget(target),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Material(
              color: scheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile(
                    key: const Key('vibration_switch'),
                    secondary: const Icon(Icons.vibration),
                    title: Text(strings.t('vibration')),
                    value: state.vibration,
                    onChanged: notifier.setVibration,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    key: const Key('sound_switch'),
                    secondary: const Icon(Icons.volume_up_outlined),
                    title: Text(strings.t('sound')),
                    value: state.sound,
                    onChanged: notifier.setSound,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
