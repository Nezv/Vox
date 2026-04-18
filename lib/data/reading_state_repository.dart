import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ReadingState {
  const ReadingState({required this.bookPath, required this.pageIndex});

  final String bookPath;
  final int pageIndex;

  Map<String, Object?> toJson() => {
        'bookPath': bookPath,
        'pageIndex': pageIndex,
      };

  static ReadingState? fromJson(Object? json) {
    if (json is! Map) return null;
    final bookPath = json['bookPath'];
    final pageIndex = json['pageIndex'];
    if (bookPath is! String || bookPath.isEmpty) return null;
    if (pageIndex is! int || pageIndex < 0) return null;
    return ReadingState(bookPath: bookPath, pageIndex: pageIndex);
  }

  ReadingState copyWith({String? bookPath, int? pageIndex}) => ReadingState(
        bookPath: bookPath ?? this.bookPath,
        pageIndex: pageIndex ?? this.pageIndex,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingState &&
          other.bookPath == bookPath &&
          other.pageIndex == pageIndex);

  @override
  int get hashCode => Object.hash(bookPath, pageIndex);
}

abstract class ReadingStateRepository {
  Future<ReadingState?> load();
  Future<void> save(ReadingState state);
  Future<void> clear();
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

  @override
  Future<ReadingState?> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return null;
      return ReadingState.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(ReadingState state) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(state.toJson()));
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
