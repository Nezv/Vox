import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../models/book.dart';
import 'library_folder.dart';

abstract class LibraryRepository {
  Future<List<Book>> loadBooks();
  Future<int> importBooks();
  Future<bool> chooseFolder();
  Future<void> delete(Book book);
  Future<Book> rename(Book book, String newBaseName);
  String? get folderPath;
}

class FileSystemLibraryRepository implements LibraryRepository {
  FileSystemLibraryRepository({LibraryFolder? folder})
      : _folder = folder ?? LibraryFolder();

  final LibraryFolder _folder;

  @override
  String? get folderPath => _folder.current;

  @override
  Future<bool> chooseFolder() => _folder.pick();

  @override
  Future<int> importBooks() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'Import markdown books',
      type: FileType.custom,
      allowedExtensions: const ['md'],
      allowMultiple: true,
    );
    if (picked == null || picked.files.isEmpty) return 0;

    final folderPath = await _folder.resolve();
    final dir = Directory(folderPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    var imported = 0;
    final seen = <String>{};
    for (final selected in picked.files) {
      final sourcePath = selected.path;
      if (sourcePath == null || sourcePath.isEmpty) continue;
      if (!seen.add(sourcePath)) continue;

      final source = File(sourcePath);
      if (!await source.exists()) continue;
      if (p.extension(source.path).toLowerCase() != '.md') continue;

      final targetPath = await _nextAvailableImportPath(
        folderPath,
        p.basenameWithoutExtension(source.path),
      );
      if (_samePath(source.path, targetPath)) {
        continue;
      }
      await source.copy(targetPath);
      imported++;
    }

    return imported;
  }

  @override
  Future<List<Book>> loadBooks() async {
    final folderPath = await _folder.resolve();
    final dir = Directory(folderPath);
    if (!await dir.exists()) return const [];

    final entries = await dir.list(followLinks: false).toList();
    final books = <Book>[];
    for (final entry in entries) {
      if (entry is! File) continue;
      if (p.extension(entry.path).toLowerCase() != '.md') continue;
      final title = p.basenameWithoutExtension(entry.path);
      books.add(Book(path: entry.path, title: title));
    }

    books.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return books;
  }

  @override
  Future<void> delete(Book book) => File(book.path).delete();

  @override
  Future<Book> rename(Book book, String newBaseName) async {
    final trimmed = newBaseName.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('New name must not be empty');
    }
    if (trimmed.contains('/') ||
        trimmed.contains('\\') ||
        trimmed.contains(':')) {
      throw ArgumentError('New name must not contain path separators');
    }
    final dir = p.dirname(book.path);
    final newPath = p.join(dir, '$trimmed.md');
    if (newPath == book.path) return book;
    if (await File(newPath).exists()) {
      throw StateError('A book named "$trimmed.md" already exists');
    }
    final renamed = await File(book.path).rename(newPath);
    final title = p.basenameWithoutExtension(renamed.path);
    return Book(path: renamed.path, title: title);
  }

  Future<String> _nextAvailableImportPath(String dir, String rawBaseName) async {
    final baseName = rawBaseName.trim().isEmpty ? 'book' : rawBaseName.trim();
    var attempt = 0;
    while (true) {
      final suffix = attempt == 0 ? '' : ' ($attempt)';
      final candidate = p.join(dir, '$baseName$suffix.md');
      if (!await File(candidate).exists()) {
        return candidate;
      }
      attempt++;
    }
  }

  bool _samePath(String a, String b) {
    final left = p.normalize(a);
    final right = p.normalize(b);
    if (Platform.isWindows) {
      return left.toLowerCase() == right.toLowerCase();
    }
    return left == right;
  }
}
