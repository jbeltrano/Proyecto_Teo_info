import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:proyecto_teo_info/features/tasks/data/models/task.dart';

abstract class AiClient {
  Future<List<Task>> extractTasks(String transcript);
}

/// Cliente para integrar con Gemini
class HttpAiClient implements AiClient {
  final String endpoint;
  final String apiKey;

  HttpAiClient({required this.endpoint, required this.apiKey});

  @override
  Future<List<Task>> extractTasks(String transcript) async {
    final body = _buildRequestBody(transcript);
    // La API de Gemini usa la key como parámetro en la URL, no en el header
    final uri = Uri.parse('$endpoint?key=$apiKey');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      return _parseTasks(data);
    } else {
      // Mostrar el error en la consola
      print('Error de IA ${res.statusCode}: ${res.body}');

      // JSON de ejemplo para devolver tareas de prueba
      final today = DateTime.now();
      
      final demo = {
        "tasks": [
          {
            "id": "demo-1",
            "title": "Comprar leche y pan",
            "notes": "Del súper cercano",
            "due_date": _formatDate(today.add(const Duration(days: 1))),
          },
          {
            "id": "demo-2",
            "title": "Enviar reporte de ventas",
            "notes": "Adjuntar gráficos",
            "due_date": _formatDate(today.add(const Duration(days: 2))),
          },
          {
            "id": "demo-23",
            "title": "Esto es una tarea de prueba",
            "notes": "Nota de prueba",
            "due_date": _formatDate(today.add(const Duration(days: 2))),
          },
        ],
      };
      return (demo['tasks'] as List)
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _buildPrompt(String transcript) {
    final today = _formatDate(DateTime.now());
    return """Eres un asistente que extrae tareas de una transcripción de voz. Analiza el siguiente texto y extrae todas las tareas mencionadas con sus fechas de vencimiento si se mencionan:

$transcript

Ten en cuenta que la fecha de hoy es: $today

IMPORTANTE: Solo debes extraer y devolver la FECHA (formato YYYY-MM-DD), NO incluyas hora ni información de tiempo. Si el usuario menciona horas, ignóralas y solo considera la fecha del día.

""";
  }

  Map<String, dynamic> _buildRequestBody(String transcript) {
    return {
      "contents": [
        {
          "parts": [
            // {"text": transcript},
            {"text": _buildPrompt(transcript)}
          ],
        },
      ],
      "generationConfig": {
        "responseMimeType": "application/json",
        "responseSchema": {
          "type": "object",
          "properties": {
            "tasks": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "id": {"type": "string", "description": "ID de la tarea."},
                  "title": {
                    "type": "string",
                    "description": "Título de la tarea.",
                  },
                  "notes": {
                    "type": "string",
                    "description": "Notas adicionales o contexto.",
                  },
                  "due_date": {
                    "type": "string",
                    "description": "Fecha de vencimiento en formato YYYY-MM-DD (solo fecha, sin hora).",
                  },
                },
                "required": ["title"],
              },
            },
          },
        },
      },
    };
  }

  List<Task> _parseTasks(Map<String, dynamic> response) {
    // Extraer el texto JSON anidado
    final candidates = response['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No se encontraron tareas en la respuesta de la IA.');
    }

    final content =
        candidates.first['content']?['parts']?.first?['text'] as String?;
    if (content == null) {
      throw Exception('Respuesta de la IA no contiene texto válido.');
    }

    // Decodificar el texto JSON para obtener las tareas
    final parsedJson = jsonDecode(content) as Map<String, dynamic>;
    final tasksJson = parsedJson['tasks'] as List?;
    if (tasksJson == null) {
      throw Exception('No se encontraron tareas en el JSON de la IA.');
    }

    // Convertir cada tarea en un objeto Task
    return tasksJson
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
