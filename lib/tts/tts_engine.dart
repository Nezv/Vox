sealed class TtsEvent {
  const TtsEvent();
}

class TtsStarted extends TtsEvent {
  const TtsStarted();
}

class TtsBoundary extends TtsEvent {
  const TtsBoundary(this.startChar, this.endChar);

  final int startChar;
  final int endChar;
}

class TtsCompleted extends TtsEvent {
  const TtsCompleted();
}

class TtsPaused extends TtsEvent {
  const TtsPaused();
}

class TtsCancelled extends TtsEvent {
  const TtsCancelled();
}

class TtsError extends TtsEvent {
  const TtsError(this.message);
  final String message;
}

abstract class TtsEngine {
  Stream<TtsEvent> get events;

  Future<void> speak(String text);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> setRate(double rate);
  Future<List<String>> getLanguages();
  Future<List<Map<String, String>>> getVoices();
  Future<void> setLanguage(String language);
  Future<void> setVoice(Map<String, String> voice);
  Future<void> dispose();
}
