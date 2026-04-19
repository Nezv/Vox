import 'package:flutter/foundation.dart';

enum ReaderFontScale { small, normal, large, xlarge }

enum ReaderFontFamily {
  timesNewRoman,
  georgia,
  garamond,
  cambria,
  sansSerif,
  verdana,
}

extension ReaderFontScaleX on ReaderFontScale {
  double get multiplier {
    switch (this) {
      case ReaderFontScale.small:
        return 0.85;
      case ReaderFontScale.normal:
        return 1.0;
      case ReaderFontScale.large:
        return 1.15;
      case ReaderFontScale.xlarge:
        return 1.3;
    }
  }

  String get label {
    switch (this) {
      case ReaderFontScale.small:
        return 'S';
      case ReaderFontScale.normal:
        return 'M';
      case ReaderFontScale.large:
        return 'L';
      case ReaderFontScale.xlarge:
        return 'XL';
    }
  }
}

extension ReaderFontFamilyX on ReaderFontFamily {
  String? get fontFamily {
    switch (this) {
      case ReaderFontFamily.timesNewRoman:
        return 'Times New Roman';
      case ReaderFontFamily.georgia:
        return 'Georgia';
      case ReaderFontFamily.garamond:
        return 'Garamond';
      case ReaderFontFamily.cambria:
        return 'Cambria';
      case ReaderFontFamily.sansSerif:
        return 'Arial';
      case ReaderFontFamily.verdana:
        return 'Verdana';
    }
  }

  String get label {
    switch (this) {
      case ReaderFontFamily.timesNewRoman:
        return 'Times New Roman';
      case ReaderFontFamily.georgia:
        return 'Georgia';
      case ReaderFontFamily.garamond:
        return 'Garamond';
      case ReaderFontFamily.cambria:
        return 'Cambria';
      case ReaderFontFamily.sansSerif:
        return 'Sans Serif';
      case ReaderFontFamily.verdana:
        return 'Verdana';
    }
  }
}

class ReaderSettings extends ChangeNotifier {
  ReaderSettings({
    ReaderFontScale scale = ReaderFontScale.normal,
    ReaderFontFamily family = ReaderFontFamily.timesNewRoman,
    double speechRate = 0.5,
  })  : _scale = scale,
        _family = family,
        _speechRate = speechRate;

  ReaderFontScale _scale;
  ReaderFontFamily _family;
  double _speechRate;

  ReaderFontScale get scale => _scale;
  ReaderFontFamily get family => _family;
  double get speechRate => _speechRate;

  void setScale(ReaderFontScale value) {
    if (_scale == value) return;
    _scale = value;
    notifyListeners();
  }

  void setFamily(ReaderFontFamily value) {
    if (_family == value) return;
    _family = value;
    notifyListeners();
  }

  void setSpeechRate(double value) {
    final clamped = value.clamp(0.25, 1.0);
    if (_speechRate == clamped) return;
    _speechRate = clamped;
    notifyListeners();
  }
}
