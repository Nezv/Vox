import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/book.dart';
import 'library_folder.dart';

abstract class LibraryRepository {
  Future<List<Book>> loadBooks();
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
  Future<List<Book>> loadBooks() async {
    final folderPath = await _folder.resolve();
    final dir = Directory(folderPath);
    if (!await dir.exists()) return const [];

    final entries = await dir.list(followLinks: false).toList();
    final books = <Book>[];
    for (final entry in entries) {
      if (entry is! File) continue;
      if (p.extension(entry.path).toLowerCase() != '.md') continue;
      final title = await _readTitle(entry);
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
    final title = await _readTitle(renamed);
    return Book(path: renamed.path, title: title);
  }

  Future<String> _readTitle(File file) async {
    try {
      final lines = await file.readAsLines();
      for (final raw in lines) {
        final line = raw.trimLeft();
        if (line.startsWith('# ')) {
          final title = line.substring(2).trim();
          if (title.isNotEmpty) return title;
        }
      }
    } catch (_) {
      // Unreadable file — fall through to filename.
    }
    return p.basenameWithoutExtension(file.path);
  }
}
