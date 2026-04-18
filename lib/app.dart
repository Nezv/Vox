import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'core/reader_settings.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'data/book_content_repository.dart';
import 'data/library_repository.dart';
import 'data/reading_state_repository.dart';
import 'models/book.dart';
import 'views/book_view.dart';
import 'views/library_view.dart';

class VoxApp extends StatefulWidget {
  const VoxApp({
    super.key,
    this.repository,
    this.contentRepository,
    this.readingStateRepository,
    this.themeController,
    this.readerSettings,
  });

  final LibraryRepository? repository;
  final BookContentRepository? contentRepository;
  final ReadingStateRepository? readingStateRepository;
  final ThemeController? themeController;
  final ReaderSettings? readerSettings;

  @override
  State<VoxApp> createState() => _VoxAppState();
}

class _VoxAppState extends State<VoxApp> {
  late final ThemeController _theme =
      widget.themeController ?? ThemeController();
  late final ReaderSettings _settings =
      widget.readerSettings ?? ReaderSettings();
  late final LibraryRepository _repository =
      widget.repository ?? FileSystemLibraryRepository();
  late final BookContentRepository _contentRepository =
      widget.contentRepository ?? const FileSystemBookContentRepository();
  late final ReadingStateRepository _stateRepository =
      widget.readingStateRepository ?? FileSystemReadingStateRepository();

  late final bool _ownsTheme = widget.themeController == null;
  late final bool _ownsSettings = widget.readerSettings == null;

  @override
  void dispose() {
    if (_ownsTheme) _theme.dispose();
    if (_ownsSettings) _settings.dispose();
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
            stateRepository: _stateRepository,
            theme: _theme,
            settings: _settings,
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
    required this.stateRepository,
    required this.theme,
    required this.settings,
  });

  final LibraryRepository repository;
  final BookContentRepository contentRepository;
  final ReadingStateRepository stateRepository;
  final ThemeController theme;
  final ReaderSettings settings;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  View _view = View.library;
  Book? _selected;
  int _initialPage = 0;
  bool _booting = true;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final saved = await widget.stateRepository.load();
    if (!mounted) return;
    if (saved == null) {
      setState(() => _booting = false);
      return;
    }
    try {
      final books = await widget.repository.loadBooks();
      if (!mounted) return;
      final match = books.where((b) => b.path == saved.bookPath).toList();
      if (match.isEmpty) {
        setState(() => _booting = false);
        return;
      }
      setState(() {
        _selected = match.first;
        _initialPage = saved.pageIndex;
        _view = View.book;
        _booting = false;
      });
    } catch (_) {
      if (mounted) setState(() => _booting = false);
    }
  }

  void _open(Book book) {
    setState(() {
      _selected = book;
      _initialPage = 0;
      _view = View.book;
    });
    widget.stateRepository.save(
      ReadingState(bookPath: book.path, pageIndex: 0),
    );
  }

  void _back() {
    setState(() => _view = View.library);
  }

  void _onPageChanged(int page) {
    final book = _selected;
    if (book == null) return;
    widget.stateRepository.save(
      ReadingState(bookPath: book.path, pageIndex: page),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    switch (_view) {
      case View.library:
        return LibraryView(repository: widget.repository, onOpen: _open);
      case View.book:
        assert(_selected != null, 'BookView requires a selected book');
        return BookView(
          book: _selected!,
          onBack: _back,
          repository: widget.contentRepository,
          settings: widget.settings,
          theme: widget.theme,
          initialPage: _initialPage,
          onPageChanged: _onPageChanged,
        );
    }
  }
}
