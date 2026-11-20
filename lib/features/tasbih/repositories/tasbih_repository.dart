import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../models/tasbih_state.dart';

/// গণনার সংরক্ষণ (SQLite)। টেস্টে এর বদলে নকল (fake) ব্যবহার করা যায়।
abstract class TasbihCounterStore {
  Future<Map<String, TasbihCounter>> loadCounters();
  Future<void> saveCounter(TasbihCounter counter);
}

class SqliteTasbihCounterStore implements TasbihCounterStore {
  @override
  Future<Map<String, TasbihCounter>> loadCounters() async {
    final db = await AppDatabase.instance.db;
    final rows = await db.query('tasbih');
    return {
      for (final r in rows)
        r['key'] as String: TasbihCounter(
          key: r['key'] as String,
          session: r['present_count'] as int,
          total: r['total_count'] as int,
          target: r['target'] as int,
        ),
    };
  }

  @override
  Future<void> saveCounter(TasbihCounter c) async {
    final db = await AppDatabase.instance.db;
    await db.insert(
      'tasbih',
      {'key': c.key, 'present_count': c.session, 'total_count': c.total, 'target': c.target},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

/// ছোট পছন্দ (SharedPreferences): বর্তমান জিকির, কম্পন, শব্দ।
class TasbihPrefsStore {
  final SharedPreferences _p;
  const TasbihPrefsStore(this._p);

  String get activeKey {
    final v = _p.getString('tasbih_active');
    return (v != null && dhikrKeys.contains(v)) ? v : dhikrKeys.first;
  }

  bool get vibration => _p.getBool('tasbih_vibration') ?? true;
  bool get sound => _p.getBool('tasbih_sound') ?? false;

  Future<void> setActiveKey(String v) => _p.setString('tasbih_active', v);
  Future<void> setVibration(bool v) => _p.setBool('tasbih_vibration', v);
  Future<void> setSound(bool v) => _p.setBool('tasbih_sound', v);
}
