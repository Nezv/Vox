import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vox/app.dart';
import 'package:vox/data/library_repository.dart';
import 'package:vox/models/book.dart';

class _FakeRepo implements LibraryRepository {
  _FakeRepo(this.books);

  List<Book> books;

  @override
  String? get folderPath => '/fake/Vox';

  @override
  Future<List<Book>> loadBooks() async => books;

  @override
  Future<bool> chooseFolder() async => false;
}

void main() {
  testWidgets('Library boots with Vox title and book rows', (tester) async {
    final repo = _FakeRepo([
      const Book(path: '/fake/Vox/alpha.md', title: 'Alpha'),
      const Book(path: '/fake/Vox/beta.md', title: 'Beta'),
    ]);

    await tester.pumpWidget(VoxApp(repository: repo));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Vox'),
      ),
      findsOneWidget,
    );
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Open sample'), findsNothing);
  });

  testWidgets('Empty folder shows the hint', (tester) async {
    await tester.pumpWidget(VoxApp(repository: _FakeRepo([])));
    await tester.pumpAndSettle();

    expect(find.text('No books in'), findsOneWidget);
    expect(find.text('/fake/Vox'), findsOneWidget);
    expect(find.textContaining('Add .md files'), findsOneWidget);
  });

  testWidgets('Library → Book → Library carries the selected book',
      (tester) async {
    final repo = _FakeRepo([
      const Book(path: '/fake/Vox/alpha.md', title: 'Alpha'),
      const Book(path: '/fake/Vox/beta.md', title: 'Beta'),
    ]);

    await tester.pumpWidget(VoxApp(repository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsNothing);

    await tester.tap(find.byTooltip('Back to library'));
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
  });
}
