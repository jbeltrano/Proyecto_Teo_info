import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voz a Texto',
      theme: ThemeData(useMaterial3: true),
      debugShowCheckedModeBanner: false, // Desactivar la etiqueta de depuración
      home: const VoiceToTextPage(),
    );
  }
}

class VoiceToTextPage extends StatefulWidget {
  const VoiceToTextPage({super.key});

  @override
  State<VoiceToTextPage> createState() => _VoiceToTextPageState();
}

class _VoiceToTextPageState extends State<VoiceToTextPage> {
  final SpeechToText _speech = SpeechToText();

  String _liveText = '';
  String? _statusMessage;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initSpeech());
  }

  Future<void> _initSpeech() async {
    final permissionStatus = await Permission.microphone.request();
    if (!permissionStatus.isGranted) {
      setState(() {
        _statusMessage = 'Se requiere permiso de micrófono.';
      });
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) => setState(() => _statusMessage = status),
      onError: (error) => setState(() => _statusMessage = error.errorMsg),
    );

    setState(() {
      _statusMessage = available
          ? 'Listo para escuchar.'
          : 'Servicio de voz no disponible.';
    });
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
        _statusMessage = 'Captura detenida.';
      });
      return;
    }

    if (!_speech.isAvailable) {
      await _initSpeech();
      if (!_speech.isAvailable) return;
    }

    final started = await _speech.listen(
      listenOptions: SpeechListenOptions(
        autoPunctuation: true,
        partialResults: true,
        listenMode: ListenMode.dictation,
        enableHapticFeedback: true,
      ),

      localeId: await _speech.systemLocale().then((value) => value?.localeId),
      onResult: (result) {
        setState(() {
          _liveText = result.recognizedWords;
        });
      },
    );

    setState(() {
      _isListening = started ?? false;
      _statusMessage = (_isListening)
          ? 'Escuchando…'
          : 'No se pudo iniciar la escucha.';
    });
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Voz a Texto')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transcripción en vivo',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _liveText.isEmpty
                            ? 'Pulsa el botón para comenzar a dictar.'
                            : _liveText,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: Icon(_isListening ? Icons.stop : Icons.mic),
                        label: Text(
                          _isListening ? 'Detener dictado' : 'Comenzar dictado',
                        ),
                        onPressed: _toggleListening,
                      ),
                    ],
                  ),
                ),
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _statusMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
