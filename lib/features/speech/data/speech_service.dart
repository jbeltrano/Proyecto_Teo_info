import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();

  Future<bool> ensureReady({
    void Function(String status)? onStatus,
    void Function(SpeechRecognitionError error)? onError,
  }) async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return false;
    return _speech.initialize(
      onStatus: (s) => onStatus?.call(s),
      onError: (e) => onError?.call(e),
    );
  }

  Future<bool> start({required void Function(String words) onResult}) async {
    HapticFeedback.lightImpact();
    final localeId = await _speech.systemLocale().then((v) => v?.localeId);
    final ok = await _speech.listen(
      onResult: (r) => onResult(r.recognizedWords),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        autoPunctuation: true,
        enableHapticFeedback: true,
        listenMode: ListenMode.dictation,
      ),
      localeId: localeId,
      pauseFor: const Duration(seconds: 2), // Tiempo de pausa para considarar que el usuario finalizó de hablar
      listenFor: const Duration(minutes: 5), // Tiempo máximo de escucha continua
    );
    return ok ?? false;
  }

  Future<void> stop() async {
    await _speech.stop();
    HapticFeedback.selectionClick();
  }

  Future<void> dispose() async {
    await _speech.cancel();
  }
}
