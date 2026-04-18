import 'dart:async';

import 'tts_engine.dart';

class NoopTtsEngine implements TtsEngine {
  NoopTtsEngine();

  final StreamController<TtsEvent> _controller =
      StreamController<TtsEvent>.broadcast();

  @override
  Stream<TtsEvent> get events => _controller.stream;

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setRate(double rate) async {}

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
