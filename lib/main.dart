import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_teo_info/features/tasks/presentation/controllers/task_controller.dart';
import 'package:proyecto_teo_info/features/tasks/data/ai/ai_client.dart';
import 'package:proyecto_teo_info/features/tasks/presentation/pages/tasks_page.dart';
import 'package:proyecto_teo_info/features/tasks/data/local/tasks_db.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar el archivo .env desde assets
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
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TaskController(
            aiClient: HttpAiClient(
              endpoint:
                  'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
              apiKey: apiKey, // apiKey en query ?key=...
              // accessToken: null, // solo si usas OAuth
            ),
            db: TasksDb(), // quítalo si aún no quieres persistencia
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
