import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vox/core/markdown/block_parser.dart';
import 'package:vox/tts/playback_controller.dart';
import 'package:vox/tts/tts_engine.dart';
import 'package:vox/views/reader/playback_bar.dart';

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
}

Widget _harness(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SafeArea(child: child)),
  );
}

void main() {
  testWidgets('renders all five transport buttons', (tester) async {
    final engine = _FakeEngine();
    final c = PlaybackController(engine: engine, blocks: [
      const Block(BlockKind.paragraph, 'one two three'),
    ]);
    await tester.pumpWidget(_harness(PlaybackBar(
      controller: c,
      onPreviousPage: () {},
      onNextPage: () {},
    )));
    expect(find.byIcon(Icons.skip_previous), findsOneWidget);
    expect(find.byIcon(Icons.replay_10), findsOneWidget);
    expect(find.byIcon(Icons.play_circle), findsOneWidget);
    expect(find.byIcon(Icons.forward_10), findsOneWidget);
    expect(find.byIcon(Icons.skip_next), findsOneWidget);
    await engine.dispose();
    c.dispose();
  });

  testWidgets('play icon toggles to pause when playing', (tester) async {
    final engine = _FakeEngine();
    final c = PlaybackController(engine: engine, blocks: [
      const Block(BlockKind.paragraph, 'one two three'),
    ]);
    await tester.pumpWidget(_harness(PlaybackBar(
      controller: c,
      onPreviousPage: () {},
      onNextPage: () {},
    )));
    expect(find.byIcon(Icons.play_circle), findsOneWidget);
    await tester.tap(find.byIcon(Icons.play_circle));
    await tester.pump();
    expect(find.byIcon(Icons.pause_circle), findsOneWidget);
    expect(engine.speakCalls, hasLength(1));
    await engine.dispose();
    c.dispose();
  });

  testWidgets('previous/next page callbacks do not call speak', (tester) async {
    final engine = _FakeEngine();
    final c = PlaybackController(engine: engine, blocks: [
      const Block(BlockKind.paragraph, 'one two three'),
    ]);
    var prev = 0;
    var next = 0;
    await tester.pumpWidget(_harness(PlaybackBar(
      controller: c,
      onPreviousPage: () => prev++,
      onNextPage: () => next++,
    )));
    await tester.tap(find.byIcon(Icons.skip_previous));
    await tester.tap(find.byIcon(Icons.skip_next));
    await tester.pump();
    expect(prev, 1);
    expect(next, 1);
    expect(engine.speakCalls, isEmpty);
    await engine.dispose();
    c.dispose();
  });

  testWidgets('forward_10 advances cursor', (tester) async {
    final engine = _FakeEngine();
    final longText = List.generate(100, (i) => 'w$i').join(' ');
    final c = PlaybackController(engine: engine, blocks: [
      Block(BlockKind.paragraph, longText),
    ]);
    await tester.pumpWidget(_harness(PlaybackBar(
      controller: c,
      onPreviousPage: () {},
      onNextPage: () {},
    )));
    expect(c.wordsSpoken, 0);
    await tester.tap(find.byIcon(Icons.forward_10));
    await tester.pump();
    expect(c.wordsSpoken, greaterThan(0));
    await engine.dispose();
    c.dispose();
  });

  testWidgets('replay_10 rewinds cursor', (tester) async {
    final engine = _FakeEngine();
    final longText = List.generate(100, (i) => 'w$i').join(' ');
    final c = PlaybackController(engine: engine, blocks: [
      Block(BlockKind.paragraph, longText),
    ]);
    await c.seek(const Duration(seconds: 20));
    final before = c.wordsSpoken;
    await tester.pumpWidget(_harness(PlaybackBar(
      controller: c,
      onPreviousPage: () {},
      onNextPage: () {},
    )));
    await tester.tap(find.byIcon(Icons.replay_10));
    await tester.pump();
    expect(c.wordsSpoken, lessThan(before));
    await engine.dispose();
    c.dispose();
  });

  testWidgets('track-mode button calls callback when not tracking',
      (tester) async {
    final engine = _FakeEngine();
    final c = PlaybackController(engine: engine, blocks: [
      const Block(BlockKind.paragraph, 'one two three'),
    ]);
    var called = 0;
    await tester.pumpWidget(_harness(PlaybackBar(
      controller: c,
      onPreviousPage: () {},
      onNextPage: () {},
      isTrackingPageView: false,
      onEnableTrackMode: () => called++,
    )));
    await tester.tap(find.byTooltip('Return to track mode'));
    await tester.pump();
    expect(called, 1);
    await engine.dispose();
    c.dispose();
  });
}
