import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vox/app.dart';
import 'package:vox/core/theme/app_theme.dart';

void main() {
  testWidgets('AppBar shows Vox title', (tester) async {
    await tester.pumpWidget(const VoxApp());

    final appBarFinder = find.descendant(
      of: find.byType(AppBar),
      matching: find.text('Vox'),
    );
    expect(appBarFinder, findsOneWidget);
  });

  testWidgets('Theme can be cycled through light, dark, sepia', (tester) async {
    await tester.pumpWidget(const VoxApp());

    for (final mode in AppThemeMode.values) {
      await tester.tap(find.text(_labelFor(mode)));
      await tester.pumpAndSettle();
    }

    expect(find.byType(SegmentedButton<AppThemeMode>), findsOneWidget);
  });
}

String _labelFor(AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.light:
      return 'Light';
    case AppThemeMode.dark:
      return 'Dark';
    case AppThemeMode.sepia:
      return 'Sepia';
  }
}
