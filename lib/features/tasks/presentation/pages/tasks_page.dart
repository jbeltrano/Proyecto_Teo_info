import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:proyecto_teo_info/features/speech/presentation/widgets/hold_mic_button.dart';
import 'package:proyecto_teo_info/features/tasks/presentation/controllers/task_controller.dart';
import 'package:proyecto_teo_info/features/tasks/presentation/widgets/task_list.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/task.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final SpeechToText _speech = SpeechToText();
  String _transcript = '';
  String _accumulatedText = ''; // Texto acumulado entre pausas
  bool _isListening = false;
  bool _shouldKeepListening = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    unawaited(_ensureReady());
  }

  Future<void> _ensureReady() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      setState(() => _status = 'Se requiere permiso de micrófono.');
      return;
    }
    final ok = await _speech.initialize(
      onStatus: (s) {
        setState(() => _status = s);
        // Cuando termina de escuchar por pausa, reiniciar automáticamente
        if (s == 'done' && _shouldKeepListening && mounted) {
          _restartListening();
        }
      },
      onError: (e) => setState(() => _status = e.errorMsg),
    );
    if (!ok) setState(() => _status = 'Servicio de voz no disponible.');
  }

  Future<void> _restartListening() async {
    if (!_shouldKeepListening) return;

    // Guardar el texto actual antes de reiniciar
    if (_transcript.isNotEmpty) {
      _accumulatedText = _accumulatedText.isEmpty
          ? _transcript
          : '$_accumulatedText $_transcript';
    }

    await Future.delayed(const Duration(milliseconds: 200));
    if (!_shouldKeepListening || !mounted) return;

    final locale = await _speech.systemLocale().then((v) => v?.localeId);
    await _speech.listen(
      onResult: (r) {
        // Combinar texto acumulado con el nuevo
        final fullText = _accumulatedText.isEmpty
            ? r.recognizedWords
            : '$_accumulatedText ${r.recognizedWords}';
        setState(() => _transcript = fullText);
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        autoPunctuation: true,
        enableHapticFeedback: true,
        listenMode: ListenMode.confirmation,
        cancelOnError: false,
      ),
      localeId: locale,
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(minutes: 10),
    );
  }

  Future<void> _start() async {
    if (_isListening) return;
    HapticFeedback.lightImpact();

    // Limpiar textos al empezar nueva sesión
    _accumulatedText = '';

    setState(() {
      _isListening = true;
      _shouldKeepListening = true;
      _transcript = '';
      _status = 'Escuchando… suelta para detener';
    });

    final locale = await _speech.systemLocale().then((v) => v?.localeId);
    await _speech.listen(
      onResult: (r) => setState(() => _transcript = r.recognizedWords),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        autoPunctuation: true,
        enableHapticFeedback: true,
        listenMode: ListenMode.confirmation,
        cancelOnError: false,
      ),
      localeId: locale,
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(minutes: 10),
    );
  }

  Future<void> _stop() async {
    if (!_isListening) return;
    _shouldKeepListening = false;
    await _speech.stop();
    setState(() {
      _isListening = false;
      _status = 'Procesando…';
    });

    // Enviar el texto transcrito a la IA
    if (!mounted) return;
    final ctrl = context.read<TaskController>();
    await ctrl.fromTranscript(_transcript);

    setState(() => _status = 'Mantén presionado para hablar');
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    String title,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showAddTaskDialog(BuildContext context, TaskController ctrl) {
    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime? dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Nueva Tarea',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notas (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      dueDate == null
                          ? 'Agregar fecha de vencimiento'
                          : '${dueDate!.year}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}',
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setModalState(() => dueDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('El título es requerido'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          final newTask = Task(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            title: titleCtrl.text.trim(),
                            notes: notesCtrl.text.trim().isEmpty
                                ? null
                                : notesCtrl.text.trim(),
                            dueDate: dueDate,
                            done: false,
                          );

                          Navigator.pop(ctx);
                          await ctrl.addTask(newTask);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Tarea creada: ${newTask.title}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: const Text('Guardar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final bottomPad = (media.viewInsets.bottom > 0)
        ? media.viewInsets.bottom + 12
        : media.padding.bottom + 12;

    TaskController? ctrl;
    try {
      ctrl = context.watch<TaskController>();
    } catch (_) {
      // If the provider is not available, keep ctrl null to avoid crashing the UI.
      ctrl = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tus tareas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await Supabase.instance.client.auth.signOut();
                await GoogleSignIn.instance.disconnect();
              } catch (e) {
                // No mostrar nada en caso de error
              }
            },
          ),
        ],
      ),
      floatingActionButton: ctrl != null
          ? FloatingActionButton(
              onPressed: () => _showAddTaskDialog(context, ctrl!),
              tooltip: 'Agregar tarea manualmente',
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          StreamBuilder<List<ConnectivityResult>>(
            stream: Connectivity().onConnectivityChanged,
            builder: (context, snap) {
              final data = snap.data ?? const <ConnectivityResult>[];
              final offline =
                  data.isEmpty || data.contains(ConnectivityResult.none);
              if (offline) {
                return Container(
                  width: double.infinity,
                  color: Colors.red.shade100,
                  padding: const EdgeInsets.all(8),
                  child: const Text(
                    'Sin conexión a Internet',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: Stack(
              children: [
                SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad + 260),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Transcripción',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _transcript.isEmpty
                                      ? 'Mantén presionado el botón para dictar...'
                                      : _transcript,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_status != null)
                          Text(_status!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        if (ctrl?.isLoading ?? false)
                          const LinearProgressIndicator(),
                        const SizedBox(height: 8),

                        // Tareas pendientes
                        _buildSectionHeader(
                          theme,
                          'Tareas Pendientes',
                          Icons.pending_actions,
                          theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        TaskList(
                          tasks: (ctrl?.tasks ?? const [])
                              .where((t) => !t.done)
                              .toList(),
                        ),

                        const SizedBox(height: 24),

                        // Tareas completadas
                        _buildSectionHeader(
                          theme,
                          'Tareas Realizadas',
                          Icons.check_circle,
                          Colors.green,
                        ),
                        const SizedBox(height: 8),
                        TaskList(
                          tasks: (ctrl?.tasks ?? const [])
                              .where((t) => t.done)
                              .toList(),
                        ),

                        if (ctrl?.error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            ctrl?.error ?? '',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: bottomPad),
                      child: HoldMicButton(
                        isActive: _isListening,
                        color: theme.colorScheme.primary,
                        canvasSize: 300,
                        ringBaseSize: 120,
                        onHoldStart: _start,
                        onHoldEnd: _stop,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
