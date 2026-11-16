import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/database/app_database.dart';

class VoiceSearchService {
  VoiceSearchService._internal();
  static final VoiceSearchService instance = VoiceSearchService._internal();

  stt.SpeechToText? _speechInstance;
  stt.SpeechToText get _speech => _speechInstance ??= stt.SpeechToText();

  FlutterTts? _ttsInstance;
  FlutterTts get _tts => _ttsInstance ??= FlutterTts();

  bool _isInitialized = false;
  bool _isTtsInitialized = false;

  bool get isListening => _speechInstance?.isListening ?? false;
  bool get isAvailable => _isInitialized;

  /// Initializes the on-device speech-to-text engine
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (val) => debugPrint('SpeechToText onError: ${val.errorMsg}'),
        onStatus: (val) => debugPrint('SpeechToText onStatus: $val'),
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('SpeechToText initialization failed: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Starts listening for a speech-to-text search query (supports English, Hindi & Hinglish)
  Future<bool> startListening({
    String? localeId,
    required Function(String text, bool isFinal) onResult,
    required VoidCallback onDone,
    required Function(String error) onError,
  }) async {
    final available = await initialize();
    if (!available) {
      onError('Speech recognition is not available or microphone permission was denied.');
      return false;
    }

    try {
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
          if (result.finalResult) {
            onDone();
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.search,
          cancelOnError: true,
          partialResults: true,
          localeId: localeId,
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 3),
        ),
      );
      return true;
    } catch (e) {
      onError('Failed to start speech recognition: $e');
      return false;
    }
  }

  /// Stops speech listening
  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  /// Cancels speech listening
  Future<void> cancelListening() async {
    await _speech.cancel();
  }

  /// Speaks a concise summary of search findings aloud if enabled in settings
  Future<void> speakResultIfEnabled(String message) async {
    try {
      final enabled = await AppDatabase.instance.getSetting('speak_search_results');
      if (enabled != 'true') return;

      if (!_isTtsInitialized) {
        await _tts.setLanguage('en-US');
        await _tts.setSpeechRate(0.5);
        await _tts.setPitch(1.0);
        _isTtsInitialized = true;
      }

      await _tts.speak(message);
    } catch (e) {
      debugPrint('Spoken search result error: $e');
    }
  }

  /// Stops any in-progress speech playback
  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
