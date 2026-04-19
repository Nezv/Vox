import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vox/app.dart';
import 'package:vox/data/book_content_repository.dart';
import 'package:vox/data/library_repository.dart';
import 'package:vox/data/reading_state_repository.dart';
import 'package:vox/models/book.dart';

class _FakeRepo implements LibraryRepository {
  _FakeRepo(this.books);

  List<Book> books;
  int deleteCalls = 0;
  int renameCalls = 0;
  String? lastRenamedTo;

  @override
  String? get folderPath => '/fake/Vox';

  @override
  Future<List<Book>> loadBooks() async => List.of(books);

  @override
  Future<int> importBooks() async => 0;

  @override
  Future<bool> chooseFolder() async => false;

  @override
  Future<void> delete(Book book) async {
    deleteCalls++;
    books = books.where((b) => b.path != book.path).toList();
  }

  @override
  Future<Book> rename(Book book, String newBaseName) async {
    renameCalls++;
    lastRenamedTo = newBaseName;
    final newPath = '/fake/Vox/$newBaseName.md';
    final renamed = Book(path: newPath, title: newBaseName);
    books = books.map((b) => b.path == book.path ? renamed : b).toList();
    return renamed;
  }
}

class _FakeContentRepo implements BookContentRepository {
  _FakeContentRepo([Map<String, String>? contents])
      : contents = Map.of(contents ?? const {});

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

class _FakeStateRepo implements ReadingStateRepository {
  _FakeStateRepo([this.stored, this._progress = const {}]);

  ReadingState? stored;
  final Map<String, double> _progress;
  int saves = 0;

  @override
  Future<ReadingState?> load() async => stored;

  @override
  Future<void> save(ReadingState state) async {
    saves++;
    stored = state;
  }

  @override
  Future<void> clear() async {
    stored = null;
  }

  @override
  Future<Map<String, double>> loadAllProgress() async => Map.of(_progress);
}

VoxApp _buildApp({
  required LibraryRepository repo,
  BookContentRepository? content,
  ReadingStateRepository? state,
}) {
  return VoxApp(
    repository: repo,
    contentRepository: content ?? _FakeContentRepo(),
    readingStateRepository: state ?? _FakeStateRepo(),
  );
}

void main() {
  testWidgets('Library boots with Vox title and book rows', (tester) async {
    final repo = _FakeRepo([
      const Book(path: '/fake/Vox/alpha.md', title: 'Alpha'),
      const Book(path: '/fake/Vox/beta.md', title: 'Beta'),
    ]);

    await tester.pumpWidget(_buildApp(repo: repo));
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
  });

  testWidgets('Empty folder shows the hint', (tester) async {
    await tester.pumpWidget(_buildApp(repo: _FakeRepo([])));
    await tester.pumpAndSettle();

    expect(find.text('No books yet'), findsOneWidget);
    expect(find.text('/fake/Vox'), findsOneWidget);
    expect(find.textContaining('Import .md files'), findsOneWidget);
  });

  testWidgets('Library → Book → Library renders content and round-trips',
      (tester) async {
    final repo = _FakeRepo([
      const Book(path: '/fake/Vox/alpha.md', title: 'Alpha'),
      const Book(path: '/fake/Vox/beta.md', title: 'Beta'),
    ]);
    final content = _FakeContentRepo({
      '/fake/Vox/alpha.md':
          '# Alpha Title\n\nFirst para.\n\n## Section\n\nSecond para.',
    });

    await tester.pumpWidget(_buildApp(repo: repo, content: content));
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
    final content = _FakeContentRepo()
      ..errors['/fake/Vox/broken.md'] = Exception('disk gone');

    await tester.pumpWidget(_buildApp(repo: repo, content: content));
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

    await tester.pumpWidget(_buildApp(repo: repo, content: content));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Blank'));
    await tester.pumpAndSettle();

    expect(find.text('Empty book'), findsOneWidget);
  });

  testWidgets('Starts in library view even when saved state exists',
      (tester) async {
    final repo = _FakeRepo([
      const Book(path: '/fake/Vox/alpha.md', title: 'Alpha'),
      const Book(path: '/fake/Vox/beta.md', title: 'Beta'),
    ]);
    final state = _FakeStateRepo(
      const ReadingState(bookPath: '/fake/Vox/beta.md', pageIndex: 0),
    );

    await tester.pumpWidget(
      _buildApp(repo: repo, state: state),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.byTooltip('Back to library'), findsNothing);
  });

  testWidgets('Invalid saved path falls back to the library', (tester) async {
    final repo = _FakeRepo([
      const Book(path: '/fake/Vox/alpha.md', title: 'Alpha'),
    ]);
    final state = _FakeStateRepo(
      const ReadingState(bookPath: '/fake/Vox/missing.md', pageIndex: 2),
    );

    await tester.pumpWidget(_buildApp(repo: repo, state: state));
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.byTooltip('Back to library'), findsNothing);
  });

  testWidgets('Opening a book saves reading state', (tester) async {
    final repo = _FakeRepo([
      const Book(path: '/fake/Vox/alpha.md', title: 'Alpha'),
    ]);
    final content = _FakeContentRepo({'/fake/Vox/alpha.md': '# Alpha\n\nbody'});
    final state = _FakeStateRepo();

    await tester.pumpWidget(
      _buildApp(repo: repo, content: content, state: state),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();

    expect(state.saves, greaterThanOrEqualTo(1));
    expect(state.stored?.bookPath, '/fake/Vox/alpha.md');
  });

  testWidgets('Rename menu renames the book through the repository',
      (tester) async {
    final repo = _FakeRepo([
      const Book(path: '/fake/Vox/alpha.md', title: 'Alpha'),
    ]);

    await tester.pumpWidget(_buildApp(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'renamed-alpha');
    await tester.tap(find.widgetWithText(TextButton, 'Rename'));
    await tester.pumpAndSettle();

    expect(repo.renameCalls, 1);
    expect(repo.lastRenamedTo, 'renamed-alpha');
    expect(find.text('renamed-alpha'), findsOneWidget);
  });

  testWidgets('Delete menu removes the book after confirmation',
      (tester) async {
    final repo = _FakeRepo([
      const Book(path: '/fake/Vox/alpha.md', title: 'Alpha'),
      const Book(path: '/fake/Vox/beta.md', title: 'Beta'),
    ]);

    await tester.pumpWidget(_buildApp(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repo.deleteCalls, 1);
    expect(find.text('Alpha'), findsNothing);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('Library shows progress bar for a book with saved progress',
      (tester) async {
    final repo = _FakeRepo([
      const Book(path: '/fake/Vox/alpha.md', title: 'Alpha'),
      const Book(path: '/fake/Vox/beta.md', title: 'Beta'),
    ]);
    final state = _FakeStateRepo(
      null,
      {'/fake/Vox/alpha.md': 0.45},
    );

    await tester.pumpWidget(_buildApp(repo: repo, state: state));
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('Wide window shows a two-page spread', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _FakeRepo([
      const Book(path: '/fake/Vox/alpha.md', title: 'Alpha'),
    ]);
    final paragraphs = List.generate(
      40,
      (i) => 'Paragraph number $i. ${List.filled(60, 'word').join(' ')}',
    );
    final content = _FakeContentRepo({
      '/fake/Vox/alpha.md': '# Alpha\n\n${paragraphs.join('\n\n')}',
    });

    await tester.pumpWidget(
      _buildApp(repo: repo, content: content),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();

    // Two ReaderPageView widgets visible side-by-side on a wide spread.
    // Imported via the widget tree — lookup by type name string avoids an
    // unnecessary public export from the production code.
    final readerPages = find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == 'ReaderPageView',
    );
    expect(readerPages, findsNWidgets(2));
  });
}
