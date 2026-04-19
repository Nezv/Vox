import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:vox/data/library_folder.dart';
import 'package:vox/data/library_repository.dart';

class _FixedFolder extends LibraryFolder {
  _FixedFolder(this.path);

  final String path;

  @override
  String? get current => path;

  @override
  Future<String> resolve() async => path;

  @override
  Future<bool> pick() async => false;
}

void main() {
  test('loadBooks uses file name instead of markdown heading', () async {
    final dir = await Directory.systemTemp.createTemp('vox_repo_titles');
    addTearDown(() => dir.delete(recursive: true));

    final file = File(p.join(dir.path, 'alpha-file.md'));
    await file.writeAsString('# Heading title\n\nBody');

    final repo = FileSystemLibraryRepository(folder: _FixedFolder(dir.path));
    final books = await repo.loadBooks();

    expect(books, hasLength(1));
    expect(books.first.title, 'alpha-file');
  });

  test('rename returns updated title from new file name', () async {
    final dir = await Directory.systemTemp.createTemp('vox_repo_rename');
    addTearDown(() => dir.delete(recursive: true));

    final file = File(p.join(dir.path, 'before.md'));
    await file.writeAsString('# Old heading\n\nBody');

    final repo = FileSystemLibraryRepository(folder: _FixedFolder(dir.path));
    final books = await repo.loadBooks();

    final renamed = await repo.rename(books.first, 'after-name');

    expect(p.basename(renamed.path), 'after-name.md');
    expect(renamed.title, 'after-name');

    final reloaded = await repo.loadBooks();
    expect(reloaded.single.title, 'after-name');
  });
}
