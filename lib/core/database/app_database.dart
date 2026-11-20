import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// বুকমার্ক, তাসবিহ কাউন্টার ও নামাজের হিসাব এখানে থাকবে।
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'islamic_app.db');
    return openDatabase(path, version: 1, onCreate: (d, v) async {
      await d.execute('''CREATE TABLE bookmarks(
        item_type TEXT NOT NULL, item_id TEXT NOT NULL, created_at TEXT NOT NULL,
        PRIMARY KEY(item_type, item_id))''');
      await d.execute('''CREATE TABLE tasbih(
        key TEXT PRIMARY KEY, present_count INTEGER NOT NULL DEFAULT 0,
        total_count INTEGER NOT NULL DEFAULT 0, target INTEGER NOT NULL DEFAULT 33)''');
      await d.execute('''CREATE TABLE salat_log(
        date TEXT NOT NULL, prayer TEXT NOT NULL, done INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY(date, prayer))''');
    });
  }
}
