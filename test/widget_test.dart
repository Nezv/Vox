import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vox/app.dart';

void main() {
  testWidgets('App boots on Library view with Vox title', (tester) async {
    await tester.pumpWidget(const VoxApp());

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Vox'),
      ),
      findsOneWidget,
    );
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Open sample'), findsOneWidget);
  });

  testWidgets('Library → Book → Library round-trip', (tester) async {
    await tester.pumpWidget(const VoxApp());

    await tester.tap(find.text('Open sample'));
    await tester.pumpAndSettle();

    expect(find.text('Book'), findsOneWidget);
    expect(find.text('Library'), findsNothing);

    await tester.tap(find.byTooltip('Back to library'));
    await tester.pumpAndSettle();

    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Book'), findsNothing);
  });
}
