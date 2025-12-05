import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_teo_info/features/tasks/presentation/controllers/task_controller.dart';
import 'package:proyecto_teo_info/features/tasks/data/ai/ai_client.dart';
import 'package:proyecto_teo_info/features/tasks/data/local/tasks_db.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:proyecto_teo_info/auth/google_auth_service.dart';
import 'package:proyecto_teo_info/auth/sign_in_page.dart';
import 'package:proyecto_teo_info/features/tasks/presentation/pages/tasks_page.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final supabase = await Supabase.initialize(
    url: dotenv.env['EXPO_PUBLIC_SUPABASE_URL']!,
    anonKey: dotenv.env['EXPO_PUBLIC_SUPABASE_KEY']!,
  );

  final googleSignIn = GoogleSignIn.instance;
  await googleSignIn.initialize(
    clientId: dotenv.env['GCP_ANDROID_CLIENT_ID'],
    serverClientId: dotenv.env['GCP_WEB_CLIENT_ID'],
  );

  final googleService = GoogleAuthService(
    supabaseClient: supabase.client,
    googleSignIn: googleSignIn,
  );

  runApp(MyApp(googleAuthService: googleService));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.googleAuthService});
  final GoogleAuthService googleAuthService;

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
              apiKey: apiKey,
            ),
            db: TasksDb(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AuthGate(googleAuthService: googleAuthService),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.googleAuthService});
  final GoogleAuthService googleAuthService;

  @override
  Widget build(BuildContext context) {
    final authStream = Supabase.instance.client.auth.onAuthStateChange.map(
      (e) => e.session,
    );
    return StreamBuilder<Session?>(
      stream: authStream,
      builder: (context, snapshot) {
        final session =
            snapshot.data ?? Supabase.instance.client.auth.currentSession;
        if (session != null) return const TasksPage();
        return SignInPage(googleAuthService: googleAuthService);
      },
    );
  }
}
