import 'package:flutter/foundation.dart';
import 'package:proyecto_teo_info/features/tasks/data/ai/ai_client.dart';
import 'package:proyecto_teo_info/features/tasks/data/models/task.dart';

class TaskController extends ChangeNotifier {
  TaskController({required this.aiClient});

  final AiClient aiClient;

  bool isLoading = false;
  String? error;
  List<Task> tasks = const [];

  /// Procesa el texto transcrito y genera tareas usando la IA
  Future<void> fromTranscript(String transcript) async {
    if (transcript.trim().isEmpty) return;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await aiClient.extractTasks(transcript);
      tasks = result;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Alterna el estado de completado de una tarea
  void toggleTaskCompletion(String taskId) {
    tasks = tasks.map((task) {
      if (task.id == taskId) {
        return task.copyWith(isCompleted: !task.isCompleted);
      }
      return task;
    }).toList();
    notifyListeners();
  }

  /// Elimina una tarea de la lista
  void deleteTask(String taskId) {
    tasks = tasks.where((task) => task.id != taskId).toList();
    notifyListeners();
  }
}
