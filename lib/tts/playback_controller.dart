import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/markdown/block_parser.dart';
import '../views/reader/paginator.dart';
import 'tts_engine.dart';

class PlaybackController extends ChangeNotifier {
  PlaybackController({
    required TtsEngine engine,
    List<Block> blocks = const [],
    double initialWordsPerSecond = 2.5,
  })  : _engine = engine,
        _wordsPerSecond = initialWordsPerSecond {
    updateBlocks(blocks);
    _subscription = _engine.events.listen(_onEvent);
  }

  final TtsEngine _engine;
  late StreamSubscription<TtsEvent> _subscription;

  List<Block> _blocks = const [];
  List<ReaderPage> _pages = const [];
  final List<List<(int, int)>> _wordRangesByBlock = [];
  int _totalWords = 0;

  double _wordsPerSecond;
  int _spokenWordsForWps = 0;
  final Stopwatch _spokenClock = Stopwatch();

  int _cursorBlockIndex = 0;
  int _cursorCharOffset = 0;
  int _utteranceStart = 0;
  int _utteranceLength = 0;
  bool _isPlaying = false;
  (int, int)? _currentWordRange;

  static const int _maxUtteranceChars = 280;

  // Public getters --------------------------------------------------------

  bool get isPlaying => _isPlaying;

  int get cursorBlockIndex => _cursorBlockIndex;
  int get cursorCharOffset => _cursorCharOffset;
  (int, int)? get currentWordRange => _currentWordRange;

  double get wordsPerSecond => _wordsPerSecond;
  int get totalWords => _totalWords;

  int get wordsSpoken {
    var count = 0;
    for (var i = 0; i < _cursorBlockIndex && i < _blocks.length; i++) {
      if (_isSpeakable(i)) count += _wordRangesByBlock[i].length;
    }
    if (_cursorBlockIndex < _blocks.length && _isSpeakable(_cursorBlockIndex)) {
      final ranges = _wordRangesByBlock[_cursorBlockIndex];
      for (final r in ranges) {
        if (r.$1 < _cursorCharOffset) {
          count++;
        } else {
          break;
        }
      }
    }
    return count;
  }

  Duration get elapsed {
    if (_wordsPerSecond <= 0) return Duration.zero;
    return Duration(
        milliseconds: (wordsSpoken / _wordsPerSecond * 1000).round());
  }

  Duration get estimatedTotal {
    if (_wordsPerSecond <= 0 || _totalWords == 0) return Duration.zero;
    return Duration(
        milliseconds: (_totalWords / _wordsPerSecond * 1000).round());
  }

  double get progress {
    if (_totalWords == 0) return 0;
    return (wordsSpoken / _totalWords).clamp(0.0, 1.0);
  }

  bool get atStart => _cursorBlockIndex == 0 && _cursorCharOffset == 0;
  bool get atEnd =>
      _cursorBlockIndex >= _blocks.length ||
      (_cursorBlockIndex == _blocks.length - 1 &&
          _isSpeakable(_cursorBlockIndex) &&
          _cursorCharOffset >= _blocks[_cursorBlockIndex].text.length);

  // Public commands -------------------------------------------------------

  void updateBlocks(List<Block> blocks) {
    _blocks = blocks;
    _wordRangesByBlock
      ..clear()
      ..addAll(blocks.map(_computeWordRanges));
    _totalWords = 0;
    for (var i = 0; i < blocks.length; i++) {
      if (_isSpeakable(i)) _totalWords += _wordRangesByBlock[i].length;
    }
    if (_cursorBlockIndex >= blocks.length) {
      _cursorBlockIndex = 0;
      _cursorCharOffset = 0;
    }
    notifyListeners();
  }

  void updatePages(List<ReaderPage> pages) {
    _pages = pages;
  }

  List<ReaderPage> get pages => _pages;

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> play() async {
    if (_blocks.isEmpty) return;
    if (_isPlaying) return;
    if (atEnd) {
      _cursorBlockIndex = 0;
      _cursorCharOffset = 0;
    }
    _isPlaying = true;
    _spokenClock.start();
    notifyListeners();
    await _speakFromCursor();
  }

  Future<void> pause() async {
    _isPlaying = false;
    _spokenClock.stop();
    await _engine.pause();
    notifyListeners();
  }

  Future<void> stop() async {
    _isPlaying = false;
    _spokenClock.stop();
    _currentWordRange = null;
    await _engine.stop();
    notifyListeners();
  }

  Future<void> seek(Duration delta) async {
    final words = (delta.inMilliseconds / 1000 * _wordsPerSecond).round();
    if (words == 0) return;
    final wasPlaying = _isPlaying;
    _isPlaying = false;
    await _engine.stop();
    if (words > 0) {
      _advanceByWords(words);
    } else {
      _rewindByWords(-words);
    }
    _currentWordRange = null;
    _isPlaying = wasPlaying;
    notifyListeners();
    if (wasPlaying) {
      await _speakFromCursor();
    }
  }

  void restoreCursor(int blockIndex, int charOffset) {
    _cursorBlockIndex = blockIndex.clamp(0, _blocks.length);
    _cursorCharOffset = charOffset;
    notifyListeners();
  }

  void reseedWps(double wps) {
    _wordsPerSecond = wps;
    _spokenWordsForWps = 0;
    _spokenClock.reset();
    notifyListeners();
  }

  Future<void> jumpToBlock(int blockIndex) async {
    if (blockIndex < 0 || blockIndex >= _blocks.length) return;
    final wasPlaying = _isPlaying;
    _isPlaying = false;
    await _engine.stop();
    _cursorBlockIndex = blockIndex;
    _cursorCharOffset = 0;
    _currentWordRange = null;
    _isPlaying = wasPlaying;
    notifyListeners();
    if (wasPlaying) await _speakFromCursor();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  // Internals -------------------------------------------------------------

  bool _isSpeakable(int blockIndex) =>
      blockIndex >= 0 &&
      blockIndex < _blocks.length &&
      _blocks[blockIndex].kind != BlockKind.blank &&
      _blocks[blockIndex].text.trim().isNotEmpty;

  Future<void> _speakFromCursor() async {
    while (_cursorBlockIndex < _blocks.length &&
        !_isSpeakable(_cursorBlockIndex)) {
      _cursorBlockIndex++;
      _cursorCharOffset = 0;
    }
    if (_cursorBlockIndex >= _blocks.length) {
      _isPlaying = false;
      _spokenClock.stop();
      notifyListeners();
      return;
    }

    final blockText = _blocks[_cursorBlockIndex].text;
    if (_cursorCharOffset >= blockText.length) {
      _advanceBlock();
      await _speakFromCursor();
      return;
    }

    _utteranceStart = _cursorCharOffset;
    final remaining = blockText.substring(_cursorCharOffset);
    final text = _takeUtteranceChunk(remaining);
    _utteranceLength = text.length;
    try {
      await _engine.speak(text);
    } catch (_) {
      _isPlaying = false;
      _spokenClock.stop();
      _currentWordRange = null;
      notifyListeners();
    }
  }

  void _onEvent(TtsEvent event) {
    switch (event) {
      case TtsStarted():
        if (!_spokenClock.isRunning && _isPlaying) _spokenClock.start();
        break;
      case TtsBoundary(:final startChar, :final endChar):
        final fullStart = _utteranceStart + startChar;
        final fullEnd = _utteranceStart + endChar;
        _currentWordRange = (fullStart, fullEnd);
        _cursorCharOffset = fullEnd;
        _spokenWordsForWps++;
        _updateWpsMaybe();
        notifyListeners();
        break;
      case TtsCompleted():
        if (_cursorBlockIndex < _blocks.length && _isSpeakable(_cursorBlockIndex)) {
          final blockLength = _blocks[_cursorBlockIndex].text.length;
          final minProgress =
              (_utteranceStart + _utteranceLength).clamp(0, blockLength);
          if (_cursorCharOffset < minProgress) {
            _cursorCharOffset = minProgress;
          }
          if (_cursorCharOffset < blockLength) {
            _currentWordRange = null;
            notifyListeners();
            if (_isPlaying) {
              _speakFromCursor();
            }
            break;
          }
        }
        _advanceBlock();
        if (_isPlaying && _cursorBlockIndex < _blocks.length) {
          _speakFromCursor();
        } else {
          _isPlaying = false;
          _currentWordRange = null;
          _spokenClock.stop();
          notifyListeners();
        }
        break;
      case TtsPaused():
        _spokenClock.stop();
        break;
      case TtsCancelled():
        break;
      case TtsError():
        _isPlaying = false;
        _spokenClock.stop();
        _currentWordRange = null;
        notifyListeners();
        break;
    }
  }

  void _advanceBlock() {
    _cursorBlockIndex++;
    _cursorCharOffset = 0;
    while (_cursorBlockIndex < _blocks.length &&
        !_isSpeakable(_cursorBlockIndex)) {
      _cursorBlockIndex++;
    }
  }

  void _advanceByWords(int words) {
    var remaining = words;
    while (remaining > 0 && _cursorBlockIndex < _blocks.length) {
      if (!_isSpeakable(_cursorBlockIndex)) {
        _cursorBlockIndex++;
        _cursorCharOffset = 0;
        continue;
      }
      final ranges = _wordRangesByBlock[_cursorBlockIndex];
      final currentIdx = _wordIndexAtOrAfter(ranges, _cursorCharOffset);
      final newIdx = currentIdx + remaining;
      if (newIdx >= ranges.length) {
        remaining -= (ranges.length - currentIdx);
        _cursorBlockIndex++;
        _cursorCharOffset = 0;
      } else {
        _cursorCharOffset = ranges[newIdx].$1;
        remaining = 0;
      }
    }
    if (_cursorBlockIndex >= _blocks.length) {
      _cursorBlockIndex = _blocks.length;
      _cursorCharOffset = 0;
    }
  }

  void _rewindByWords(int words) {
    var remaining = words;
    while (remaining > 0) {
      if (_cursorBlockIndex >= _blocks.length) {
        _cursorBlockIndex = _blocks.length - 1;
        if (_cursorBlockIndex < 0) return;
        if (_isSpeakable(_cursorBlockIndex)) {
          final ranges = _wordRangesByBlock[_cursorBlockIndex];
          _cursorCharOffset = ranges.isEmpty ? 0 : ranges.last.$2;
        }
      }
      if (_cursorBlockIndex < 0) {
        _cursorBlockIndex = 0;
        _cursorCharOffset = 0;
        return;
      }
      if (!_isSpeakable(_cursorBlockIndex)) {
        _cursorBlockIndex--;
        continue;
      }
      final ranges = _wordRangesByBlock[_cursorBlockIndex];
      final currentIdx = _wordIndexAtOrAfter(ranges, _cursorCharOffset);
      final newIdx = currentIdx - remaining;
      if (newIdx < 0) {
        remaining -= currentIdx;
        _cursorBlockIndex--;
        if (_cursorBlockIndex < 0) {
          _cursorBlockIndex = 0;
          _cursorCharOffset = 0;
          return;
        }
        if (_isSpeakable(_cursorBlockIndex)) {
          final prev = _wordRangesByBlock[_cursorBlockIndex];
          _cursorCharOffset = prev.isEmpty ? 0 : prev.last.$2;
        } else {
          _cursorCharOffset = 0;
        }
      } else {
        _cursorCharOffset = ranges[newIdx].$1;
        remaining = 0;
      }
    }
  }

  int _wordIndexAtOrAfter(List<(int, int)> ranges, int charOffset) {
    for (var i = 0; i < ranges.length; i++) {
      if (ranges[i].$1 >= charOffset) return i;
    }
    return ranges.length;
  }

  void _updateWpsMaybe() {
    if (_spokenWordsForWps < 30) return;
    final seconds = _spokenClock.elapsedMilliseconds / 1000;
    if (seconds < 20) return;
    final observed = _spokenWordsForWps / seconds;
    if (observed <= 0) return;
    const alpha = 0.3;
    _wordsPerSecond = (1 - alpha) * _wordsPerSecond + alpha * observed;
  }

  static final _wordPattern = RegExp(r'\S+');

  String _takeUtteranceChunk(String text) {
    if (text.length <= _maxUtteranceChars) return text;
    final candidate = text.substring(0, _maxUtteranceChars);
    var cut = -1;
    for (var i = candidate.length - 1; i >= candidate.length ~/ 2; i--) {
      final ch = candidate.codeUnitAt(i);
      if (ch == 32 || ch == 10 || ch == 9) {
        cut = i + 1;
        break;
      }
    }
    if (cut <= 0) cut = _maxUtteranceChars;
    return text.substring(0, cut);
  }

  List<(int, int)> _computeWordRanges(Block block) {
    if (block.kind == BlockKind.blank) return const [];
    return _wordPattern
        .allMatches(block.text)
        .map((m) => (m.start, m.end))
        .toList(growable: false);
  }
}
