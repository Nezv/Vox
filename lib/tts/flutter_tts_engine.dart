import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

import 'tts_engine.dart';

class FlutterTtsEngine implements TtsEngine {
  FlutterTtsEngine() {
    _init();
  }

  final FlutterTts _tts = FlutterTts();
  final StreamController<TtsEvent> _controller =
      StreamController<TtsEvent>.broadcast();
  String _lastUtterance = '';

  Future<void> _init() async {
    await _tts.awaitSpeakCompletion(true);
    _tts.setStartHandler(() => _emit(const TtsStarted()));
    _tts.setCompletionHandler(() => _emit(const TtsCompleted()));
    _tts.setPauseHandler(() => _emit(const TtsPaused()));
    _tts.setCancelHandler(() => _emit(const TtsCancelled()));
    _tts.setErrorHandler((msg) => _emit(TtsError(msg?.toString() ?? 'tts error')));
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
    _lastUtterance = text;
    await _tts.stop();
    if (text.trim().isEmpty) {
      _emit(const TtsCompleted());
      return;
    }
    await _tts.speak(text);
  }

  @override
  Future<void> pause() async {
    await _tts.pause();
  }

  @override
  Future<void> resume() async {
    if (_lastUtterance.isEmpty) return;
    await _tts.speak(_lastUtterance);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  @override
  Future<void> setRate(double rate) async {
    await _tts.setSpeechRate(rate.clamp(0.0, 1.0));
  }

  @override
  Future<void> dispose() async {
    await _tts.stop();
    await _controller.close();
  }
}
