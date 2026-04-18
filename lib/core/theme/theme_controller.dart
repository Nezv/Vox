import 'package:flutter/foundation.dart';

import 'app_theme.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({AppThemeMode initial = AppThemeMode.light}) : _mode = initial;

  AppThemeMode _mode;
  AppThemeMode get mode => _mode;

  void setMode(AppThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }
}
