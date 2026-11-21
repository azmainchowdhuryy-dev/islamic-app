import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/localization/app_strings.dart';
import 'package:islamic_app/core/services/prefs.dart';
import 'package:islamic_app/features/tasbih/models/tasbih_state.dart';
import 'package:islamic_app/features/tasbih/providers/tasbih_provider.dart';
import 'package:islamic_app/features/tasbih/repositories/tasbih_repository.dart';
import 'package:islamic_app/features/tasbih/screens/tasbih_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ডাটাবেসের বদলে মেমরিতে রাখা নকল স্টোর (টেস্টের জন্য)।
class FakeCounterStore implements TasbihCounterStore {
  final Map<String, TasbihCounter> data = {};

  @override
  Future<Map<String, TasbihCounter>> loadCounters() async => Map.of(data);

  @override
  Future<void> saveCounter(TasbihCounter counter) async {
    data[counter.key] = counter;
  }
}

class DelayedCounterStore extends FakeCounterStore {
  final Completer<Map<String, TasbihCounter>> loadCompleter =
      Completer<Map<String, TasbihCounter>>();

  @override
  Future<Map<String, TasbihCounter>> loadCounters() => loadCompleter.future;
}

ProviderContainer makeContainer(FakeCounterStore store, SharedPreferences prefs) {
  final c = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    tasbihCounterStoreProvider.overrideWithValue(store),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  late FakeCounterStore store;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = FakeCounterStore();
  });

  group('counter logic', () {
    test('saved counters load before interactions are accepted', () async {
      final delayedStore = DelayedCounterStore();
      final container = makeContainer(delayedStore, prefs);
      final notifier = container.read(tasbihProvider.notifier);

      expect(container.read(tasbihProvider).isLoading, isTrue);
      expect(notifier.increment(), isFalse);
      expect(container.read(tasbihProvider).active.session, 0);

      delayedStore.loadCompleter.complete({
        'durood': const TasbihCounter(
          key: 'durood',
          session: 9,
          total: 22,
          target: 100,
        ),
      });
      await notifier.ready;

      final restored = container.read(tasbihProvider);
      expect(restored.isLoading, isFalse);
      expect(restored.active.session, 9);
      expect(restored.active.total, 22);

      notifier.increment();
      expect(container.read(tasbihProvider).active.session, 10);
      expect(container.read(tasbihProvider).active.total, 23);
    });

    test('increment raises session and lifetime total by one', () async {
      final c = makeContainer(store, prefs);
      final n = c.read(tasbihProvider.notifier);
      await n.ready;

      n.increment();
      n.increment();
      n.increment();

      final active = c.read(tasbihProvider).active;
      expect(active.session, 3);
      expect(active.total, 3);
    });

    test('reset clears session but keeps lifetime total', () async {
      final c = makeContainer(store, prefs);
      final n = c.read(tasbihProvider.notifier);
      await n.ready;

      for (var i = 0; i < 5; i++) {
        n.increment();
      }
      n.resetSession();

      final active = c.read(tasbihProvider).active;
      expect(active.session, 0);
      expect(active.total, 5);
    });

    test('each dhikr has its own counter', () async {
      final c = makeContainer(store, prefs);
      final n = c.read(tasbihProvider.notifier);
      await n.ready;

      n.increment();
      n.increment();
      n.selectDhikr('istighfar');
      n.increment();

      final st = c.read(tasbihProvider);
      expect(st.counters['durood']!.session, 2);
      expect(st.counters['istighfar']!.session, 1);

      n.resetSession(); // শুধু ইস্তিগফার রিসেট হবে
      expect(c.read(tasbihProvider).counters['istighfar']!.session, 0);
      expect(c.read(tasbihProvider).counters['durood']!.session, 2);
    });

    test('target completion is reported exactly once', () async {
      final c = makeContainer(store, prefs);
      final n = c.read(tasbihProvider.notifier);
      await n.ready;
      n.setTarget(33);

      final results = <bool>[for (var i = 0; i < 34; i++) n.increment()];

      expect(results.indexOf(true), 32); // ৩৩তম ট্যাপে
      expect(results.where((r) => r).length, 1);
      expect(c.read(tasbihProvider).active.completed, isTrue);
      expect(c.read(tasbihProvider).active.progress, 1.0);
    });

    test('progress follows the selected target', () async {
      final c = makeContainer(store, prefs);
      final n = c.read(tasbihProvider.notifier);
      await n.ready;
      n.setTarget(100);
      for (var i = 0; i < 25; i++) {
        n.increment();
      }
      expect(c.read(tasbihProvider).active.progress, 0.25);
    });
  });

  group('persistence', () {
    test('all values survive closing and reopening the app', () async {
      final first = makeContainer(store, prefs);
      final n = first.read(tasbihProvider.notifier);
      await n.ready;

      n.setTarget(500); // durood
      for (var i = 0; i < 5; i++) {
        n.increment();
      }
      n.selectDhikr('istighfar');
      n.setTarget(1000);
      n.increment();
      n.increment();
      n.setVibration(false);
      n.setSound(true);

      // অ্যাপ বন্ধ করে আবার খোলা: নতুন container, একই সংরক্ষিত ডেটা
      final second = makeContainer(store, prefs);
      await second.read(tasbihProvider.notifier).ready;
      final st = second.read(tasbihProvider);

      expect(st.activeKey, 'istighfar');
      expect(st.vibration, isFalse);
      expect(st.sound, isTrue);
      expect(st.counters['durood']!.session, 5);
      expect(st.counters['durood']!.total, 5);
      expect(st.counters['durood']!.target, 500);
      expect(st.counters['istighfar']!.session, 2);
      expect(st.counters['istighfar']!.target, 1000);
    });

    test('defaults: durood selected, vibration on, sound off, target 33', () async {
      final c = makeContainer(store, prefs);
      await c.read(tasbihProvider.notifier).ready;
      final st = c.read(tasbihProvider);
      expect(st.activeKey, 'durood');
      expect(st.vibration, isTrue);
      expect(st.sound, isFalse);
      expect(st.active.target, 33);
    });

    test('lifetime total stays after reset and reopen', () async {
      final first = makeContainer(store, prefs);
      final n = first.read(tasbihProvider.notifier);
      await n.ready;
      for (var i = 0; i < 4; i++) {
        n.increment();
      }
      n.resetSession();

      final second = makeContainer(store, prefs);
      await second.read(tasbihProvider.notifier).ready;
      final active = second.read(tasbihProvider).active;
      expect(active.session, 0);
      expect(active.total, 4);
    });
  });

  group('localization', () {
    test('Bengali uses Bengali numerals, English uses English numerals', () {
      expect(const AppStrings('bn').digits(1000), '১০০০');
      expect(const AppStrings('en').digits(1000), '1000');
    });

    test('every tasbih label exists in both languages', () {
      const keys = [
        'durood', 'istighfar', 'session_count', 'total_count', 'target',
        'select_target', 'tap_to_count', 'target_completed', 'target_done_label',
        'reset', 'reset_title', 'reset_body', 'cancel', 'vibration', 'sound',
      ];
      for (final k in keys) {
        expect(const AppStrings('bn').t(k), isNot(k), reason: 'bn missing $k');
        expect(const AppStrings('en').t(k), isNot(k), reason: 'en missing $k');
      }
      expect(const AppStrings('bn').t('durood'), 'দরুদ শরিফ');
      expect(const AppStrings('bn').t('istighfar'), 'ইস্তিগফার');
    });
  });

  group('screen', () {
    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          tasbihCounterStoreProvider.overrideWithValue(store),
        ],
        child: const MaterialApp(home: TasbihScreen()),
      ));
      await tester.pump();
      for (var i = 0;
          i < 5 && find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
          i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
    }

    String textOf(WidgetTester tester, String key) =>
        tester.widget<Text>(find.byKey(Key(key))).data!;

    testWidgets('tap counts up in Bengali numerals', (tester) async {
      await pumpScreen(tester);
      expect(textOf(tester, 'session_count'), '০');

      await tester.tap(find.byKey(const Key('tap_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('tap_button')));
      await tester.pump();

      expect(textOf(tester, 'session_count'), '২');
      expect(textOf(tester, 'total_count'), '২');
    });

    testWidgets('reset asks for confirmation and keeps lifetime total', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('tap_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('tap_button')));
      await tester.pump();

      await tester.ensureVisible(find.byKey(const Key('reset_button')));
      await tester.tap(find.byKey(const Key('reset_button')));
      await tester.pumpAndSettle();
      expect(find.text('রিসেট করবেন?'), findsOneWidget);

      // বাতিল করলে কিছু বদলায় না
      await tester.tap(find.byKey(const Key('cancel_reset')));
      await tester.pumpAndSettle();
      expect(textOf(tester, 'session_count'), '২');

      await tester.ensureVisible(find.byKey(const Key('reset_button')));
      await tester.tap(find.byKey(const Key('reset_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_reset')));
      await tester.pumpAndSettle();

      expect(textOf(tester, 'session_count'), '০');
      expect(textOf(tester, 'total_count'), '২');
    });
  });
}
