import 'dart:io';

abstract class BookContentRepository {
  Future<String> read(String path);
}

class FileSystemBookContentRepository implements BookContentRepository {
  const FileSystemBookContentRepository();

  @override
  Future<String> read(String path) => File(path).readAsString();
}
