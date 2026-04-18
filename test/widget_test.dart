import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vox/app.dart';
import 'package:vox/data/book_content_repository.dart';
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

class _FakeContentRepo implements BookContentRepository {
  _FakeContentRepo(this.contents);

  final Map<String, String> contents;
  final Map<String, Object> errors = {};
  int reads = 0;

  @override
  Future<String> read(String path) async {
    reads++;
    final err = errors[path];
    if (err != null) throw err;
    return contents[path] ?? '';
  }
}

void main() {
  testWidgets('Library boots with Vox title and book rows', (tester) async {
    final repo = _FakeRepo([
      const Book(path: '/fake/Vox/alpha.md', title: 'Alpha'),
      const Book(path: '/fake/Vox/beta.md', title: 'Beta'),
    ]);

    await tester.pumpWidget(VoxApp(
      repository: repo,
      contentRepository: _FakeContentRepo(const {}),
    ));
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
    await tester.pumpWidget(VoxApp(
      repository: _FakeRepo([]),
      contentRepository: _FakeContentRepo(const {}),
    ));
    await tester.pumpAndSettle();

    expect(find.text('No books in'), findsOneWidget);
    expect(find.text('/fake/Vox'), findsOneWidget);
    expect(find.textContaining('Add .md files'), findsOneWidget);
  });

  testWidgets('Library → Book → Library renders content and round-trips',
      (tester) async {
    final repo = _FakeRepo([
      const Book(path: '/fake/Vox/alpha.md', title: 'Alpha'),
      const Book(path: '/fake/Vox/beta.md', title: 'Beta'),
    ]);
    final content = _FakeContentRepo({
      '/fake/Vox/alpha.md':
          '# Alpha\n\nFirst para.\n\n## Section\n\nSecond para.',
    });

    await tester.pumpWidget(VoxApp(repository: repo, contentRepository: content));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();

    expect(find.text('First para.'), findsOneWidget);
    expect(find.text('Section'), findsOneWidget);
    expect(find.text('Second para.'), findsOneWidget);
    expect(find.text('Beta'), findsNothing);

    await tester.tap(find.byTooltip('Back to library'));
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('Book error state surfaces failure and Retry re-reads',
      (tester) async {
    final repo = _FakeRepo([
      const Book(path: '/fake/Vox/broken.md', title: 'Broken'),
    ]);
    final content = _FakeContentRepo(const {})
      ..errors['/fake/Vox/broken.md'] = Exception('disk gone');

    await tester.pumpWidget(VoxApp(repository: repo, contentRepository: content));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Broken'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't open book"), findsOneWidget);
    expect(find.textContaining('disk gone'), findsOneWidget);
    expect(content.reads, 1);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(content.reads, 2);
    expect(find.text("Couldn't open book"), findsOneWidget);
  });

  testWidgets('Book with empty content shows the Empty book hint',
      (tester) async {
    final repo = _FakeRepo([
      const Book(path: '/fake/Vox/blank.md', title: 'Blank'),
    ]);
    final content = _FakeContentRepo({'/fake/Vox/blank.md': '\n\n'});

    await tester.pumpWidget(VoxApp(repository: repo, contentRepository: content));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Blank'));
    await tester.pumpAndSettle();

    expect(find.text('Empty book'), findsOneWidget);
  });
}
