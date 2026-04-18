import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'data/book_content_repository.dart';
import 'data/library_repository.dart';
import 'models/book.dart';
import 'views/book_view.dart';
import 'views/library_view.dart';

class VoxApp extends StatefulWidget {
  const VoxApp({super.key, this.repository, this.contentRepository});

  final LibraryRepository? repository;
  final BookContentRepository? contentRepository;

  @override
  State<VoxApp> createState() => _VoxAppState();
}

class _VoxAppState extends State<VoxApp> {
  final ThemeController _theme = ThemeController();
  late final LibraryRepository _repository =
      widget.repository ?? FileSystemLibraryRepository();
  late final BookContentRepository _contentRepository =
      widget.contentRepository ?? const FileSystemBookContentRepository();

  @override
  void dispose() {
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _theme,
      builder: (context, _) {
        return MaterialApp(
          title: kAppTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeFor(_theme.mode),
          home: AppShell(
            repository: _repository,
            contentRepository: _contentRepository,
          ),
        );
      },
    );
  }
}

enum View { library, book }

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.repository,
    required this.contentRepository,
  });

  final LibraryRepository repository;
  final BookContentRepository contentRepository;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  View _view = View.library;
  Book? _selected;

  void _open(Book book) =>
      setState(() {
        _selected = book;
        _view = View.book;
      });

  void _back() => setState(() => _view = View.library);

  @override
  Widget build(BuildContext context) {
    switch (_view) {
      case View.library:
        return LibraryView(repository: widget.repository, onOpen: _open);
      case View.book:
        assert(_selected != null, 'BookView requires a selected book');
        return BookView(
          book: _selected!,
          onBack: _back,
          repository: widget.contentRepository,
        );
    }
  }
}
