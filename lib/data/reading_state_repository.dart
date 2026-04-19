import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ReadingState {
  const ReadingState({
    required this.bookPath,
    required this.pageIndex,
    this.blockIndex = 0,
    this.charOffset = 0,
    this.progressFraction = 0.0,
  });

  final String bookPath;
  final int pageIndex;
  final int blockIndex;
  final int charOffset;
  final double progressFraction;

  Map<String, Object?> toJson() => {
        'bookPath': bookPath,
        'pageIndex': pageIndex,
        'blockIndex': blockIndex,
        'charOffset': charOffset,
        'progressFraction': progressFraction,
      };

  static ReadingState? fromJson(Object? json, {String? bookPath}) {
    if (json is! Map) return null;
    final path = bookPath ?? json['bookPath'];
    final pageIndex = json['pageIndex'];
    if (path is! String || path.isEmpty) return null;
    if (pageIndex is! int || pageIndex < 0) return null;
    return ReadingState(
      bookPath: path,
      pageIndex: pageIndex,
      blockIndex: (json['blockIndex'] as int?) ?? 0,
      charOffset: (json['charOffset'] as int?) ?? 0,
      progressFraction: (json['progressFraction'] as num?)?.toDouble() ?? 0.0,
    );
  }

  ReadingState copyWith({
    String? bookPath,
    int? pageIndex,
    int? blockIndex,
    int? charOffset,
    double? progressFraction,
  }) =>
      ReadingState(
        bookPath: bookPath ?? this.bookPath,
        pageIndex: pageIndex ?? this.pageIndex,
        blockIndex: blockIndex ?? this.blockIndex,
        charOffset: charOffset ?? this.charOffset,
        progressFraction: progressFraction ?? this.progressFraction,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingState &&
          other.bookPath == bookPath &&
          other.pageIndex == pageIndex &&
          other.blockIndex == blockIndex &&
          other.charOffset == charOffset);

  @override
  int get hashCode => Object.hash(bookPath, pageIndex, blockIndex, charOffset);
}

abstract class ReadingStateRepository {
  Future<ReadingState?> load();
  Future<void> save(ReadingState state);
  Future<void> clear();
  Future<Map<String, double>> loadAllProgress();
}

class FileSystemReadingStateRepository implements ReadingStateRepository {
  FileSystemReadingStateRepository();

  Future<File> _file() async {
    final docs = await getApplicationDocumentsDirectory();
    final voxDir = Directory(p.join(docs.path, 'Vox'));
    if (!await voxDir.exists()) {
      await voxDir.create(recursive: true);
    }
    return File(p.join(voxDir.path, '.state.json'));
  }

  Future<(String? last, Map<String, Map<String, Object?>> books)>
      _readRaw() async {
    try {
      final file = await _file();
      if (!await file.exists()) return (null, <String, Map<String, Object?>>{});
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return (null, <String, Map<String, Object?>>{});
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return (null, <String, Map<String, Object?>>{});

      // Old format: top-level object has bookPath key
      if (decoded.containsKey('bookPath')) {
        final path = decoded['bookPath'] as String?;
        if (path == null || path.isEmpty) return (null, <String, Map<String, Object?>>{});
        return (
          path,
          {
            path: Map<String, Object?>.from(decoded),
          }
        );
      }

      // New format: { last: path, books: { path: {...} } }
      final last = decoded['last'] as String?;
      final rawBooks = decoded['books'];
      if (rawBooks is! Map) return (last, <String, Map<String, Object?>>{});
      final books = <String, Map<String, Object?>>{};
      for (final entry in rawBooks.entries) {
        final key = entry.key as String?;
        if (key == null) continue;
        final val = entry.value;
        if (val is Map) books[key] = Map<String, Object?>.from(val);
      }
      return (last, books);
    } catch (_) {
      return (null, <String, Map<String, Object?>>{});
    }
  }

  @override
  Future<ReadingState?> load() async {
    final (last, books) = await _readRaw();
    if (last == null) return null;
    final entry = books[last];
    if (entry == null) return null;
    return ReadingState.fromJson(entry, bookPath: last);
  }

  @override
  Future<Map<String, double>> loadAllProgress() async {
    final (_, books) = await _readRaw();
    return {
      for (final e in books.entries)
        e.key: (e.value['progressFraction'] as num?)?.toDouble() ?? 0.0,
    };
  }

  @override
  Future<void> save(ReadingState state) async {
    final (last, books) = await _readRaw();
    books[state.bookPath] = {
      'pageIndex': state.pageIndex,
      'blockIndex': state.blockIndex,
      'charOffset': state.charOffset,
      'progressFraction': state.progressFraction,
    };
    final file = await _file();
    await file.writeAsString(jsonEncode({
      'last': state.bookPath,
      'books': books,
    }));
  }

  @override
  Future<void> clear() async {
    try {
      final file = await _file();
      if (await file.exists()) await file.delete();
    } catch (_) {
      // best-effort
    }
  }
}
