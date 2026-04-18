import 'package:flutter/foundation.dart';

enum ReaderFontScale { small, normal, large, xlarge }

enum ReaderFontFamily { serif, sans, system }

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
      case ReaderFontFamily.serif:
        return 'Georgia';
      case ReaderFontFamily.sans:
        return 'Inter';
      case ReaderFontFamily.system:
        return null;
    }
  }

  String get label {
    switch (this) {
      case ReaderFontFamily.serif:
        return 'Serif';
      case ReaderFontFamily.sans:
        return 'Sans';
      case ReaderFontFamily.system:
        return 'System';
    }
  }
}

class ReaderSettings extends ChangeNotifier {
  ReaderSettings({
    ReaderFontScale scale = ReaderFontScale.normal,
    ReaderFontFamily family = ReaderFontFamily.serif,
  })  : _scale = scale,
        _family = family;

  ReaderFontScale _scale;
  ReaderFontFamily _family;

  ReaderFontScale get scale => _scale;
  ReaderFontFamily get family => _family;

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
}
