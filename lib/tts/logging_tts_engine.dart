import 'dart:async';

import 'package:flutter/foundation.dart';

import 'tts_engine.dart';

class LoggingTtsEngine implements TtsEngine {
  LoggingTtsEngine(
    this._inner, {
    this.label = 'tts',
  }) {
    _subscription = _inner.events.listen((event) {
      _log('event ${_formatEvent(event)}');
      _controller.add(event);
    });
  }

  final TtsEngine _inner;
  final String label;

  final StreamController<TtsEvent> _controller =
      StreamController<TtsEvent>.broadcast();
  late final StreamSubscription<TtsEvent> _subscription;

  @override
  Stream<TtsEvent> get events => _controller.stream;

  @override
  Future<void> speak(String text) async {
    _log('speak chars=${text.length}');
    await _inner.speak(text);
  }

  @override
  Future<void> pause() async {
    _log('pause');
    await _inner.pause();
  }

  @override
  Future<void> resume() async {
    _log('resume');
    await _inner.resume();
  }

  @override
  Future<void> stop() async {
    _log('stop');
    await _inner.stop();
  }

  @override
  Future<void> setRate(double rate) async {
    _log('setRate $rate');
    await _inner.setRate(rate);
  }

  @override
  Future<List<String>> getLanguages() async {
    _log('getLanguages');
    return _inner.getLanguages();
  }

  @override
  Future<List<Map<String, String>>> getVoices() async {
    _log('getVoices');
    return _inner.getVoices();
  }

  @override
  Future<void> setLanguage(String language) async {
    _log('setLanguage $language');
    await _inner.setLanguage(language);
  }

  @override
  Future<void> setVoice(Map<String, String> voice) async {
    _log('setVoice ${voice['name'] ?? voice}');
    await _inner.setVoice(voice);
  }

  @override
  Future<void> dispose() async {
    _log('dispose');
    await _subscription.cancel();
    await _inner.dispose();
    await _controller.close();
  }

  void _log(String message) {
    debugPrint('[TTS][$label] $message');
  }

  String _formatEvent(TtsEvent event) {
    return switch (event) {
      TtsStarted() => 'started',
      TtsBoundary(:final startChar, :final endChar) =>
        'boundary start=$startChar end=$endChar',
      TtsCompleted() => 'completed',
      TtsPaused() => 'paused',
      TtsCancelled() => 'cancelled',
      TtsError(:final message) => 'error $message',
    };
  }
}
