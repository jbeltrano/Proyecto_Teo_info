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
}
