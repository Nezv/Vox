import 'dart:async';

import 'tts_engine.dart';

class SimulatedTtsEngine implements TtsEngine {
  SimulatedTtsEngine({double initialWordsPerSecond = 2.5})
      : _wordsPerSecond = initialWordsPerSecond;

  final StreamController<TtsEvent> _controller =
      StreamController<TtsEvent>.broadcast();

  Timer? _ticker;
  double _wordsPerSecond;

  String _activeLanguage = 'en-US';
  Map<String, String> _activeVoice = const {
    'name': 'Simulated Voice',
    'locale': 'en-US',
  };

  List<(int, int)> _wordRanges = const [];
  int _nextWordIndex = 0;
  bool _isSpeaking = false;
  bool _isPaused = false;

  static final RegExp _wordPattern = RegExp(r'\S+');

  @override
  Stream<TtsEvent> get events => _controller.stream;

  @override
  Future<void> speak(String text) async {
    await stop();
    _wordRanges = _wordPattern
        .allMatches(text)
        .map((m) => (m.start, m.end))
        .toList(growable: false);
    _nextWordIndex = 0;

    if (_wordRanges.isEmpty) {
      _emit(const TtsCompleted());
      return;
    }

    _isSpeaking = true;
    _isPaused = false;
    _emit(const TtsStarted());
    _startTicker();
  }

  @override
  Future<void> pause() async {
    if (!_isSpeaking || _isPaused) return;
    _isPaused = true;
    _ticker?.cancel();
    _ticker = null;
    _emit(const TtsPaused());
  }

  @override
  Future<void> resume() async {
    if (!_isSpeaking || !_isPaused) return;
    _isPaused = false;
    _startTicker();
  }

  @override
  Future<void> stop() async {
    final hadActivePlayback = _isSpeaking || _isPaused;
    _ticker?.cancel();
    _ticker = null;
    _isSpeaking = false;
    _isPaused = false;
    _nextWordIndex = 0;
    if (hadActivePlayback) {
      _emit(const TtsCancelled());
    }
  }

  @override
  Future<void> setRate(double rate) async {
    _wordsPerSecond = (rate * 5.0).clamp(0.5, 8.0);
    if (_isSpeaking && !_isPaused) {
      _ticker?.cancel();
      _startTicker();
    }
  }

  @override
  Future<List<String>> getLanguages() async => const ['en-US'];

  @override
  Future<List<Map<String, String>>> getVoices() async => const [
        {'name': 'Simulated Voice', 'locale': 'en-US'},
      ];

  @override
  Future<void> setLanguage(String language) async {
    _activeLanguage = language;
  }

  @override
  Future<void> setVoice(Map<String, String> voice) async {
    _activeVoice = Map<String, String>.from(voice);
    _activeLanguage = _activeVoice['locale'] ?? _activeLanguage;
  }

  @override
  Future<void> dispose() async {
    _ticker?.cancel();
    _ticker = null;
    await _controller.close();
  }

  void _startTicker() {
    final intervalMs = (1000 / _wordsPerSecond).round().clamp(60, 2000);
    _ticker = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (_nextWordIndex >= _wordRanges.length) {
        _ticker?.cancel();
        _ticker = null;
        _isSpeaking = false;
        _isPaused = false;
        _emit(const TtsCompleted());
        return;
      }

      final range = _wordRanges[_nextWordIndex];
      _nextWordIndex++;
      _emit(TtsBoundary(range.$1, range.$2));
    });
  }

  void _emit(TtsEvent event) {
    if (_controller.isClosed) return;
    _controller.add(event);
  }
}
