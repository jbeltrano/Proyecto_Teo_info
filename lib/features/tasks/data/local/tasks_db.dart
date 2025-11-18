import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/task.dart';

class TasksDb {
  static const _dbName = 'tasks.db';
  static const _table = 'tasks';
  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
CREATE TABLE $_table(
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  notes TEXT,
  due_date TEXT,
  done INTEGER NOT NULL DEFAULT 0
)
''');
      },
    );
    return _db!;
  }

  Future<List<Task>> getAll() async {
    final db = await _open();
    final rows = await db.query(
      _table,
      orderBy: 'done ASC, due_date IS NULL, due_date ASC',
    );
    return rows.map((r) => Task.fromJson(r)).toList();
  }

  Future<void> upsertAll(List<Task> tasks) async {
    final db = await _open();
    final batch = db.batch();
    for (final t in tasks) {
      batch.insert(_table, {
        'id': t.id,
        'title': t.title,
        'notes': t.notes,
        'due_date': t.dueDate?.toIso8601String(),
        'done': t.done ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateDone(String id, bool done) async {
    final db = await _open();
    await db.update(
      _table,
      {'done': done ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateTask(Task t) async {
    final db = await _open();
    await db.update(
      _table,
      {
        'title': t.title,
        'notes': t.notes,
        'due_date': t.dueDate?.toIso8601String(),
        'done': t.done ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [t.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _open();
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
