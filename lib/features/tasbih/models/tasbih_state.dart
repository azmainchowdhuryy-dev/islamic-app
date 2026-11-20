/// দুটি জিকির: key দিয়ে চেনা যায় (এই key-ই লোকালাইজেশনেও ব্যবহার হয়)।
const List<String> dhikrKeys = ['durood', 'istighfar'];

/// বেছে নেওয়ার মতো লক্ষ্য।
const List<int> tasbihTargets = [33, 100, 500, 1000];

/// একটি জিকিরের হিসাব।
class TasbihCounter {
  final String key;
  final int session; // বর্তমান গণনা (রিসেট করা যায়)
  final int total; // মোট গণনা (রিসেটে মুছে না)
  final int target;

  const TasbihCounter({required this.key, this.session = 0, this.total = 0, this.target = 33});

  bool get completed => target > 0 && session >= target;

  double get progress {
    if (target <= 0) return 0.0;
    if (session >= target) return 1.0;
    return session / target;
  }

  TasbihCounter copyWith({int? session, int? total, int? target}) => TasbihCounter(
        key: key,
        session: session ?? this.session,
        total: total ?? this.total,
        target: target ?? this.target,
      );
}

/// তাসবিহ স্ক্রিনের পুরো অবস্থা।
class TasbihState {
  final String activeKey;
  final Map<String, TasbihCounter> counters;
  final bool vibration;
  final bool sound;

  const TasbihState({
    required this.activeKey,
    required this.counters,
    required this.vibration,
    required this.sound,
  });

  TasbihCounter get active => counters[activeKey]!;

  TasbihState copyWith({
    String? activeKey,
    Map<String, TasbihCounter>? counters,
    bool? vibration,
    bool? sound,
  }) =>
      TasbihState(
        activeKey: activeKey ?? this.activeKey,
        counters: counters ?? this.counters,
        vibration: vibration ?? this.vibration,
        sound: sound ?? this.sound,
      );
}
