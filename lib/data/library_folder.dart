import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LibraryFolder {
  LibraryFolder();

  String? _current;

  String? get current => _current;

  Future<String> resolve() async {
    return _current ??= await _defaultFolder();
  }

  Future<bool> pick() async {
    final picked = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose a folder with .md books',
    );
    if (picked == null) return false;
    _current = picked;
    return true;
  }

  Future<String> _defaultFolder() async {
    final docs = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(docs.path, 'Vox'));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder.path;
  }
}
