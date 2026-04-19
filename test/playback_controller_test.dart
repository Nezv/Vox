import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:vox/core/markdown/block_parser.dart';
import 'package:vox/tts/playback_controller.dart';
import 'package:vox/tts/tts_engine.dart';

class _FakeEngine implements TtsEngine {
  final StreamController<TtsEvent> _controller =
      StreamController<TtsEvent>.broadcast();
  final List<String> speakCalls = [];
  int pauseCalls = 0;
  int stopCalls = 0;

  @override
  Stream<TtsEvent> get events => _controller.stream;

  @override
  Future<void> speak(String text) async {
    speakCalls.add(text);
    _controller.add(const TtsStarted());
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    _controller.add(const TtsPaused());
  }

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {
    stopCalls++;
    _controller.add(const TtsCancelled());
  }

  @override
  Future<void> setRate(double rate) async {}

  @override
  Future<List<String>> getLanguages() async => const [];

  @override
  Future<List<Map<String, String>>> getVoices() async => const [];

  @override
  Future<void> setLanguage(String language) async {}

  @override
  Future<void> setVoice(Map<String, String> voice) async {}

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  void emit(TtsEvent event) => _controller.add(event);
}

void main() {
  List<Block> parse(String s) => parseMarkdownBlocks(s);

  test('totalWords matches non-blank block word count', () async {
    final engine = _FakeEngine();
    final blocks = parse('# Title\n\nalpha beta gamma.\n\n## H2\n\none two.');
    final c = PlaybackController(engine: engine, blocks: blocks);
    expect(c.totalWords, 1 + 3 + 1 + 2);
    await engine.dispose();
    c.dispose();
  });

  test('seek(+10s) advances 25 words at default WPS', () async {
    final engine = _FakeEngine();
    final longBlock = Block(BlockKind.paragraph,
        List.generate(100, (i) => 'w$i').join(' '));
    final c = PlaybackController(engine: engine, blocks: [longBlock]);
    await c.seek(const Duration(seconds: 10));
    expect(c.cursorBlockIndex, 0);
    expect(c.wordsSpoken, 25);
    await engine.dispose();
    c.dispose();
  });

  test('seek(-10s) at start clamps to (0, 0)', () async {
    final engine = _FakeEngine();
    const block = Block(BlockKind.paragraph, 'one two three four');
    final c = PlaybackController(engine: engine, blocks: [block]);
    await c.seek(const Duration(seconds: -10));
    expect(c.cursorBlockIndex, 0);
    expect(c.cursorCharOffset, 0);
    await engine.dispose();
    c.dispose();
  });

  test('seek crosses block boundaries', () async {
    final engine = _FakeEngine();
    final blocks = [
      const Block(BlockKind.paragraph, 'a b c d e'),
      const Block(BlockKind.blank, ''),
      const Block(BlockKind.paragraph, 'f g h i j'),
    ];
    final c = PlaybackController(engine: engine, blocks: blocks);
    await c.seek(const Duration(seconds: 3));
    expect(c.wordsSpoken, greaterThanOrEqualTo(5));
    expect(c.cursorBlockIndex, 2);
    await engine.dispose();
    c.dispose();
  });

  test('TtsCompleted advances cursor to next non-blank block', () async {
    final engine = _FakeEngine();
    final blocks = [
      const Block(BlockKind.paragraph, 'one'),
      const Block(BlockKind.blank, ''),
      const Block(BlockKind.paragraph, 'two'),
    ];
    final c = PlaybackController(engine: engine, blocks: blocks);
    await c.play();
    engine.emit(const TtsCompleted());
    await Future<void>.delayed(Duration.zero);
    expect(c.cursorBlockIndex, 2);
    await engine.dispose();
    c.dispose();
  });

  test('updatePages does not reset cursor', () async {
    final engine = _FakeEngine();
    final blocks = [const Block(BlockKind.paragraph, 'one two three')];
    final c = PlaybackController(engine: engine, blocks: blocks);
    await c.seek(const Duration(seconds: 1));
    final beforeOffset = c.cursorCharOffset;
    c.updatePages(const []);
    expect(c.cursorCharOffset, beforeOffset);
    await engine.dispose();
    c.dispose();
  });

  test('boundary advances cursorCharOffset', () async {
    final engine = _FakeEngine();
    final blocks = [const Block(BlockKind.paragraph, 'alpha beta gamma')];
    final c = PlaybackController(engine: engine, blocks: blocks);
    await c.play();
    engine.emit(const TtsBoundary(0, 5));
    await Future<void>.delayed(Duration.zero);
    expect(c.cursorCharOffset, 5);
    expect(c.currentWordRange, (0, 5));
    await engine.dispose();
    c.dispose();
  });

  test('restoreCursor seeds block and char offset', () async {
    final engine = _FakeEngine();
    final blocks = [
      const Block(BlockKind.paragraph, 'one two three'),
      const Block(BlockKind.paragraph, 'four five six'),
    ];
    final c = PlaybackController(engine: engine, blocks: blocks);
    c.restoreCursor(1, 5);
    expect(c.cursorBlockIndex, 1);
    expect(c.cursorCharOffset, 5);
    await engine.dispose();
    c.dispose();
  });

  test('reseedWps resets elapsed time estimate', () async {
    final engine = _FakeEngine();
    final blocks = [
      Block(BlockKind.paragraph, List.generate(50, (i) => 'w$i').join(' ')),
    ];
    final c = PlaybackController(
      engine: engine,
      blocks: blocks,
      initialWordsPerSecond: 2.5,
    );
    await c.seek(const Duration(seconds: 10));
    final before = c.wordsSpoken;
    c.reseedWps(5.0);
    expect(c.wordsPerSecond, 5.0);
    // wordsSpoken unchanged — only the rate changed
    expect(c.wordsSpoken, before);
    await engine.dispose();
    c.dispose();
  });

  test('long block is chunked and advances without boundary events', () async {
    final engine = _FakeEngine();
    final block = Block(
      BlockKind.paragraph,
      List.generate(140, (i) => 'word$i').join(' '),
    );
    final c = PlaybackController(engine: engine, blocks: [block]);

    await c.play();
    expect(engine.speakCalls, isNotEmpty);
    expect(engine.speakCalls.first.length, lessThanOrEqualTo(280));

    for (var i = 0; i < 20 && c.cursorBlockIndex < 1; i++) {
      engine.emit(const TtsCompleted());
      await Future<void>.delayed(Duration.zero);
    }

    expect(c.cursorBlockIndex, 1);
    await engine.dispose();
    c.dispose();
  });
}
