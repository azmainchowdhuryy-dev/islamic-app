import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/prefs.dart';
import '../models/tasbih_state.dart';
import '../repositories/tasbih_repository.dart';

final tasbihCounterStoreProvider =
    Provider<TasbihCounterStore>((ref) => SqliteTasbihCounterStore());

final tasbihPrefsStoreProvider =
    Provider<TasbihPrefsStore>((ref) => TasbihPrefsStore(ref.watch(sharedPrefsProvider)));

class TasbihNotifier extends Notifier<TasbihState> {
  late TasbihCounterStore _store;
  late TasbihPrefsStore _prefs;

  /// সংরক্ষিত গণনা লোড শেষ হলে সম্পূর্ণ হয় (টেস্টে অপেক্ষা করার জন্য)।
  Future<void> ready = Future<void>.value();

  @override
  TasbihState build() {
    _store = ref.read(tasbihCounterStoreProvider);
    _prefs = ref.read(tasbihPrefsStoreProvider);
    ready = _loadCounters();
    return TasbihState(
      activeKey: _prefs.activeKey,
      counters: {for (final k in dhikrKeys) k: TasbihCounter(key: k)},
      vibration: _prefs.vibration,
      sound: _prefs.sound,
    );
  }

  Future<void> _loadCounters() async {
    try {
      final saved = await _store.loadCounters();
      if (saved.isEmpty) return;
      state = state.copyWith(counters: {...state.counters, ...saved});
    } catch (_) {
      // লোড ব্যর্থ হলে শূন্য থেকে শুরু; অ্যাপ চলতে থাকবে।
    }
  }

  void _putCounter(TasbihCounter c) {
    state = state.copyWith(counters: {...state.counters, c.key: c});
    _store.saveCounter(c);
  }

  /// এক গণনা বাড়ায়। এই ট্যাপে লক্ষ্য পূর্ণ হলে true ফেরত দেয় (একবারই)।
  bool increment() {
    final c = state.active;
    final next = c.copyWith(session: c.session + 1, total: c.total + 1);
    _putCounter(next);
    return next.session == next.target;
  }

  /// শুধু বর্তমান গণনা শূন্য করে; মোট গণনা থাকে।
  void resetSession() {
    _putCounter(state.active.copyWith(session: 0));
  }

  void setTarget(int target) {
    _putCounter(state.active.copyWith(target: target));
  }

  void selectDhikr(String key) {
    if (!dhikrKeys.contains(key)) return;
    _prefs.setActiveKey(key);
    state = state.copyWith(activeKey: key);
  }

  void setVibration(bool on) {
    _prefs.setVibration(on);
    state = state.copyWith(vibration: on);
  }

  void setSound(bool on) {
    _prefs.setSound(on);
    state = state.copyWith(sound: on);
  }
}

final tasbihProvider = NotifierProvider<TasbihNotifier, TasbihState>(TasbihNotifier.new);
