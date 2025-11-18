import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:proyecto_teo_info/features/tasks/data/models/task.dart';

abstract class AiClient {
  Future<List<Task>> extractTasks(String transcript);
}

class MockAiClient implements AiClient {
  @override
  Future<List<Task>> extractTasks(String transcript) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final demo = {
      "tasks": [
        {
          "id": "demo-1",
          "title": "Comprar leche y pan",
          "notes": "Del súper cercano",
          "due_date": DateTime.now()
              .add(const Duration(days: 1))
              .toIso8601String(),
        },
        {
          "id": "demo-2",
          "title": "Enviar reporte de ventas",
          "notes": "Adjuntar gráficos",
          "due_date": DateTime.now()
              .add(const Duration(days: 2))
              .toIso8601String(),
        },
      ],
    };
    return (demo['tasks'] as List)
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Cliente HTTP para Gemini. Usa apiKey (query ?key=...) o accessToken (Bearer).
class HttpAiClient implements AiClient {
  final String endpoint;
  final String? apiKey; // Generative Language API
  final String? accessToken; // OAuth (Vertex o GL con OAuth)

  HttpAiClient({required this.endpoint, this.apiKey, this.accessToken})
    : assert(
        apiKey != null || accessToken != null,
        'Provee apiKey o accessToken',
      );

  @override
  Future<List<Task>> extractTasks(String transcript) async {
    final body = _buildRequestBody(transcript);

    final base = Uri.parse(endpoint);
    final uri = base.replace(
      queryParameters: {
        ...base.queryParameters,
        if (apiKey != null) 'key': apiKey!,
      },
    );

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };

    // Logs de depuración
    debugPrint('[AI] POST $uri');
    debugPrint('[AI] Request body: ${jsonEncode(body)}');

    http.Response res;
    try {
      res = await http.post(uri, headers: headers, body: jsonEncode(body));
    } catch (e) {
      debugPrint('[AI] Http error: $e');
      return _demoTasks();
    }

    debugPrint('[AI] Status: ${res.statusCode}');
    debugPrint('[AI] Raw body: ${res.body}');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      return _parseTasks(data);
    } else {
      debugPrint('[AI] Error de IA ${res.statusCode}: ${res.body}');
      return _demoTasks();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _buildPrompt(String transcript) {
    final today = _formatDate(DateTime.now());
    return """Eres un asistente que extrae tareas de una transcripción de voz. Analiza el siguiente texto y extrae todas las tareas mencionadas con sus fechas de vencimiento si se mencionan:

$transcript

Ten en cuenta que la fecha de hoy es: $today.

Reglas:
1. Interpreta fechas relativas como "mañana", "pasado mañana", "el jueves de la otra semana" usando la fecha de hoy como referencia.
2. Devuelve las fechas en formato YYYY-MM-DD.
3. Si no hay una fecha clara, omite el campo `due_date`.
4. Devuelve la respuesta en formato JSON con la siguiente estructura:
{
  "tasks": [
    {
      "title": "<TÍTULO DE LA TAREA>",
      "due_date": "<FECHA DE VENCIMIENTO EN FORMATO YYYY-MM-DD>"
    },
    ...
  ]
}

Ejemplo:
Input: "comprar carro para mañana, casa para pasado mañana y 3 pares de zapatos para el jueves de la otra semana"
Output: {
  "tasks": [
    {"title": "Comprar carro", "due_date": "2025-11-18"},
    {"title": "Comprar casa", "due_date": "2025-11-19"},
    {"title": "Comprar 3 pares de zapatos", "due_date": "2025-11-27"}
  ]
}
""";
  }

  Map<String, dynamic> _buildRequestBody(String transcript) {
    final now = DateTime.now();
    final tz = now.timeZoneOffset;
    final tzSign = tz.isNegative ? '-' : '+';
    final tzH = tz.inHours.abs().toString().padLeft(2, '0');
    final tzM = (tz.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final tzLabel = '$tzSign$tzH:$tzM';

    final dateContext =
        'La fecha de hoy es ${now.toIso8601String()}. Estamos en el año ${now.year}. Zona horaria local: $tzLabel.';

    final systemText =
        '''
Eres un extractor de tareas. Tu ÚNICA respuesta debe ser SOLO JSON válido según el schema provisto.

- Idioma: Español.
- CONTEXTO DE TIEMPO: $dateContext
- REGLA DE FECHA: La `due_date` DEBE estar en el AÑO ACTUAL (${now.year}) si la expresión de tiempo no incluye un año diferente. Si la expresión es relativa ("mañana", "lunes"), calcúlala usando el CONTEXTO DE TIEMPO.
- Formato `due_date`: ISO 8601 completo con zona horaria local (ej: 2025-11-08T00:00:00$tzLabel). Si no hay hora, usa T00:00:00.
- Si NO hay una indicación de fecha CLARA, `due_date` debe ser OMITIDA.

- Título: DEBE ser conciso, único e imperativo (una acción clara).
- Notes: Contexto breve extraído del enunciado. Puede ser omitido si no hay información extra.
- IMPORTANTE: Si un campo `id` no es proporcionado en el enunciado, **OMÍTELO**. NO inventes IDs.
''';

    return {
      "systemInstruction": {
        "parts": [
          {"text": systemText},
        ],
      },
      "contents": [
        {
          "role": "user",
          "parts": [
            // {"text": transcript},
            {"text": _buildPrompt(transcript)},
          ],
        },
      ],
      "generationConfig": {
        "temperature": 0.2,
        "topP": 0.9,
        "responseMimeType": "application/json",
        "responseSchema": {
          "type": "object",
          "properties": {
            "tasks": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "id": {"type": "string"},
                  "title": {"type": "string"},
                  "notes": {"type": "string"},
                  "due_date": {
                    "type": "string",
                    "description":
                        "Fecha de vencimiento en formato YYYY-MM-DD (solo fecha, sin hora).",
                  },
                },
                "required": ["title"],
              },
            },
          },
          "required": ["tasks"],
        },
      },
    };
  }

  List<Task> _demoTasks() {
    final demo = {
      "tasks": [
        {
          "id": "demo-1",
          "title": "Comprar leche y pan",
          "notes": "Del súper cercano",
          "due_date": DateTime.now()
              .add(const Duration(days: 1))
              .toIso8601String(),
        },
        {
          "id": "demo-2",
          "title": "Enviar reporte de ventas",
          "notes": "Adjuntar gráficos",
          "due_date": DateTime.now()
              .add(const Duration(days: 2))
              .toIso8601String(),
        },
      ],
    };
    return (demo['tasks'] as List)
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<Task> _parseTasks(Map<String, dynamic> response) {
    final candidates = response['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Sin candidatos en la respuesta de IA.');
    }
    final content =
        candidates.first['content']?['parts']?.first?['text'] as String?;
    debugPrint('[AI] text payload: $content');
    if (content == null) {
      throw Exception('Respuesta de IA sin texto JSON.');
    }
    final parsed = jsonDecode(content) as Map<String, dynamic>;
    final tasksJson = parsed['tasks'] as List?;
    debugPrint('[AI] tasks count: ${tasksJson?.length ?? 0}');
    if (tasksJson == null) {
      throw Exception('JSON de IA sin "tasks".');
    }
    return tasksJson
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
