import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'tts/flutter_tts_engine.dart';
import 'tts/logging_tts_engine.dart';
import 'tts/noop_tts_engine.dart';
import 'tts/simulated_tts_engine.dart';
import 'tts/tts_engine.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const requestedMode = String.fromEnvironment('VOX_TTS', defaultValue: 'auto');
  const trace = bool.fromEnvironment('VOX_TTS_TRACE', defaultValue: false);
  final mode = _resolveMode(requestedMode);

  final baseEngine = _engineForMode(mode);
  final engine = trace
      ? LoggingTtsEngine(baseEngine, label: mode)
      : baseEngine;

  if (trace) {
    debugPrint('[TTS][bootstrap] mode=$mode trace=true');
  }

  runApp(VoxApp(ttsEngine: engine));
}

String _resolveMode(String rawMode) {
  final mode = rawMode.toLowerCase();
  if (mode == 'real' || mode == 'mock' || mode == 'noop') return mode;
  if (mode.isNotEmpty && mode != 'auto') {
    debugPrint('[TTS][bootstrap] unknown VOX_TTS="$mode"; using auto');
  }
  if (kDebugMode && defaultTargetPlatform == TargetPlatform.windows) {
    return 'mock';
  }
  return 'real';
}

TtsEngine _engineForMode(String mode) {
  switch (mode) {
    case 'mock':
      return SimulatedTtsEngine();
    case 'noop':
      return NoopTtsEngine();
    case 'real':
      return FlutterTtsEngine();
    default:
      debugPrint('[TTS][bootstrap] unknown VOX_TTS="$mode"; using real');
      return FlutterTtsEngine();
  }
}
