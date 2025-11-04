import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_teo_info/features/tasks/presentation/controllers/task_controller.dart';
import 'package:proyecto_teo_info/features/tasks/data/ai/ai_client.dart';
import 'package:proyecto_teo_info/features/tasks/presentation/pages/tasks_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar el archivo .env desde los assets
  try {
    await dotenv.load(fileName: '.env');
    print('.env loaded successfully');
  } catch (e, st) {
    print('Error loading .env: $e\n$st');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TaskController(
            aiClient: HttpAiClient(
              endpoint:
                  'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
              apiKey: dotenv.env['API_KEY']!, // Carga la clave desde .env
            ),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Tareas por voz',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: const TasksPage(),
      ),
    );
  }
}
