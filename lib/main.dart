import 'package:flutter/material.dart';

import 'app.dart';
import 'tts/flutter_tts_engine.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(VoxApp(ttsEngine: FlutterTtsEngine()));
}
