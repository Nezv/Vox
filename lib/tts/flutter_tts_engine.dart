import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

import 'tts_engine.dart';

class FlutterTtsEngine implements TtsEngine {
  FlutterTtsEngine() {
    _ready = _init();
  }

  final FlutterTts _tts = FlutterTts();
  final StreamController<TtsEvent> _controller =
      StreamController<TtsEvent>.broadcast();
  String _lastUtterance = '';
  late final Future<void> _ready;

  Future<void> _init() async {
    // awaitSpeakCompletion is not supported on all platforms; ignore errors.
    try {
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {}
    _tts.setStartHandler(() => _emit(const TtsStarted()));
    _tts.setCompletionHandler(() => _emit(const TtsCompleted()));
    _tts.setPauseHandler(() => _emit(const TtsPaused()));
    _tts.setCancelHandler(() => _emit(const TtsCancelled()));
    _tts.setErrorHandler(
        (msg) => _emit(TtsError(msg?.toString() ?? 'tts error')));
    _tts.setProgressHandler((text, start, end, word) {
      _emit(TtsBoundary(start, end));
    });
  }

  void _emit(TtsEvent event) {
    if (_controller.isClosed) return;
    _controller.add(event);
  }

  @override
  Stream<TtsEvent> get events => _controller.stream;

  @override
  Future<void> speak(String text) async {
    try {
      await _ready;
      _lastUtterance = text;
      await _tts.stop();
      if (text.trim().isEmpty) {
        _emit(const TtsCompleted());
        return;
      }
      await _tts.speak(text);
    } catch (e) {
      _emit(TtsError(e.toString()));
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _ready;
      await _tts.pause();
    } catch (_) {
      // SAPI on Windows may not support pause; fall back to stop.
      try {
        await _tts.stop();
      } catch (_) {}
    }
  }

  @override
  Future<void> resume() async {
    try {
      await _ready;
      if (_lastUtterance.isEmpty) return;
      await _tts.speak(_lastUtterance);
    } catch (e) {
      _emit(TtsError(e.toString()));
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  @override
  Future<void> setRate(double rate) async {
    try {
      await _ready;
      await _tts.setSpeechRate(rate.clamp(0.0, 1.0));
    } catch (_) {}
  }

  @override
  Future<List<String>> getLanguages() async {
    try {
      await _ready;
      final raw = await _tts.getLanguages;
      if (raw is! List) return const [];
      return raw.whereType<String>().toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<Map<String, String>>> getVoices() async {
    try {
      await _ready;
      final raw = await _tts.getVoices;
      if (raw is! List) return const [];
      return raw.whereType<Map>().map((m) {
        return m.map((k, v) => MapEntry(k.toString(), v.toString()));
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> setLanguage(String language) async {
    try {
      await _ready;
      await _tts.setLanguage(language);
    } catch (_) {}
  }

  @override
  Future<void> setVoice(Map<String, String> voice) async {
    try {
      await _ready;
      await _tts.setVoice(voice);
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    try {
      await _tts.stop();
    } catch (_) {}
    await _controller.close();
  }
}
