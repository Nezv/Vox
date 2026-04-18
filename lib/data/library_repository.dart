import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/book.dart';
import 'library_folder.dart';

abstract class LibraryRepository {
  Future<List<Book>> loadBooks();
  Future<bool> chooseFolder();
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
