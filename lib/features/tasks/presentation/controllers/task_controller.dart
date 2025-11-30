import 'package:flutter/foundation.dart';
import '../../../tasks/data/models/task.dart';
import '../../../tasks/data/ai/ai_client.dart';
import '../../data/local/tasks_db.dart'; // opcional si usas SQLite
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class TaskController extends ChangeNotifier {
  final AiClient aiClient;
  final TasksDb? db; // opcional

  TaskController({required this.aiClient, this.db}) {
    _load();
  }

  List<Task> tasks = [];
  bool isLoading = false;
  String? error;

  Future<void> _load() async {
    if (db == null) return;
    tasks = await db!.getAll();
    notifyListeners();
  }

  Future<bool> _isOnline() async {
    try {
      final conn = await Connectivity().checkConnectivity();
      var ok = conn != ConnectivityResult.none;
      if (!ok) {
        // Fallback a un ping DNS rápido
        final res = await InternetAddress.lookup(
          'google.com',
        ).timeout(const Duration(seconds: 3));
        ok = res.isNotEmpty && res.first.rawAddress.isNotEmpty;
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<void> fromTranscript(String text) async {
    isLoading = true;
    error = null;
    notifyListeners();

    if (!await _isOnline()) {
      error = 'Sin conexión a Internet';
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final items = await aiClient.extractTasks(text);
      tasks = [...tasks, ...items];
      if (db != null) await db!.upsertAll(tasks);
    } catch (e) {
      error = 'Error: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleDone(String id, bool value) async {
    final idx = tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    tasks[idx] = tasks[idx].copyWith(done: value);
    notifyListeners();
    if (db != null) await db!.updateDone(id, value);
  }

  Future<void> deleteTask(String id) async {
    final idx = tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final removed = tasks[idx];
    tasks.removeAt(idx);
    notifyListeners();
    try {
      if (db != null) {
        await db!.delete(id);
      }
    } catch (e) {
      // rollback si falla la persistencia
      tasks.insert(idx, removed);
      notifyListeners();
      debugPrint('DB delete error: $e');
    }
  }

  Future<void> updateTask(Task updated) async {
    final i = tasks.indexWhere((t) => t.id == updated.id);
    if (i == -1) return;
    tasks[i] = updated;
    notifyListeners();
    if (db != null) {
      try {
        await db!.updateTask(updated);
      } catch (e) {
        debugPrint('DB update error: $e');
      }
    }
  }

  Future<void> addTask(Task task) async {
    tasks.add(task);
    notifyListeners();
    if (db != null) {
      try {
        await db!.upsertAll([task]);
      } catch (e) {
        debugPrint('DB add error: $e');
      }
    }
  }
}
